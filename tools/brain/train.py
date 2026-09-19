import math, json, time, sys
import numpy as np, torch
from ncps.wirings import AutoNCP
from ncps.torch import CfC

torch.manual_seed(7); np.random.seed(7)
torch.set_num_threads(12)

IN, OUT, UNITS = 15, 4, 108
NAMES_IN = ["hunger","sleepy","joy","sinT","cosT","activity","awdx","awdy","awnear","wallx","wally","petted","noise1","noise2","game"]

def ou(x, mu, tau, sigma, dt):
    return x + (mu - x) * dt / tau + sigma * math.sqrt(1) * torch.randn_like(x) * torch.sqrt(dt)

@torch.no_grad()
def make_batch(B, T):
    """Simulate B teacher-driven dragons for T steps; returns inputs (B,T,14), targets (B,T,4), dt (B,T)."""
    dt0 = torch.empty(B).uniform_(0.05, 0.25)
    dts = dt0[:, None] * torch.empty(B, T).uniform_(0.7, 1.3)
    hunger = torch.rand(B); sleepy = torch.rand(B) ** 1.5; joy = torch.rand(B)
    phase = torch.rand(B) * 2 * math.pi
    act = torch.rand(B) * 0.5
    px = torch.rand(B); py = torch.rand(B)
    cx = torch.rand(B); cy = torch.rand(B)
    petted = torch.zeros(B)
    n1 = torch.randn(B) * 0.4; n2 = torch.randn(B) * 0.4
    theta = torch.rand(B) * 2 * math.pi
    mu_h, mu_s, mu_j = torch.rand(B), torch.rand(B) ** 1.5, torch.rand(B)
    game = (torch.rand(B) < 0.4).float()      # tag mini-game: attention target is the cursor, and it must be dodged
    X = torch.zeros(B, T, IN); Y = torch.zeros(B, T, OUT)
    for t in range(T):
        dt = dts[:, t]
        hunger = (hunger + (mu_h - hunger) * dt / 60 + 0.01 * torch.randn(B) * dt.sqrt()).clamp(0, 1)
        sleepy = (sleepy + (mu_s - sleepy) * dt / 60 + 0.01 * torch.randn(B) * dt.sqrt()).clamp(0, 1)
        joy = (joy + (mu_j - joy) * dt / 60 + 0.01 * torch.randn(B) * dt.sqrt()).clamp(0, 1)
        # occasional regime changes (fed, woke up, cheered up...)
        ch = torch.rand(B) < 0.004 * dt / 0.1
        mu_h = torch.where(ch, torch.rand(B), mu_h); mu_s = torch.where(ch, torch.rand(B) ** 1.5, mu_s); mu_j = torch.where(ch, torch.rand(B), mu_j)
        # window switches: activity impulse + new attention target
        sw = torch.rand(B) < 0.04 * dt
        act = (act * torch.exp(-dt / 15) + 0.3 * sw.float()).clamp(0, 1)
        cx = torch.where(sw, torch.rand(B), cx); cy = torch.where(sw, torch.rand(B), cy)
        g_on = game > 0.5
        cx = torch.where(g_on, (cx + 0.5 * dt * torch.randn(B)).clamp(0, 1), cx)     # a cursor that drifts and jumps about
        cy = torch.where(g_on, (cy + 0.5 * dt * torch.randn(B)).clamp(0, 1), cy)
        game = torch.where(torch.rand(B) < 0.004 * dt / 0.1, (torch.rand(B) < 0.4).float(), game)
        pet = torch.rand(B) < 0.02 * dt
        petted = petted * torch.exp(-dt / 1.5) + pet.float()
        petted = petted.clamp(0, 1)
        n1 = (n1 + (0 - n1) * dt / 2.5 + 0.55 * dt.sqrt() * torch.randn(B)).clamp(-1, 1)
        n2 = (n2 + (0 - n2) * dt / 2.5 + 0.55 * dt.sqrt() * torch.randn(B)).clamp(-1, 1)
        wallx = ((px - 0.5) * 2).clamp(-1, 1) ** 3
        wally = ((py - 0.5) * 2).clamp(-1, 1) ** 3
        awdx = ((cx - px) * 2).clamp(-1, 1); awdy = ((cy - py) * 2).clamp(-1, 1)
        awnear = (1 - torch.sqrt(awdx ** 2 + awdy ** 2) / math.sqrt(2)).clamp(0, 1)
        X[:, t] = torch.stack([hunger, sleepy, joy, torch.sin(phase), torch.cos(phase), act, awdx, awdy, awnear, wallx, wally, petted, n1, n2, game], 1)
        # ---------------- teacher policy ----------------
        speed = (0.2 + 0.7 * joy * (1 - sleepy) + 0.25 * hunger).clamp(0, 1)
        speed = torch.where(sleepy > 0.75, speed * 0.15, speed)
        att = 1.2 * joy * (1 - sleepy) * (0.25 + 0.75 * act)
        # tag: sprint, and run *away* from the cursor, harder the closer it gets
        speed = torch.where(game > 0.5, (0.85 + 0.15 * awnear), speed)
        att = torch.where(game > 0.5, -1.8 * (0.4 + awnear), att)
        wander = math.pi * n1
        vdx = torch.cos(wander) + att * awdx - 1.6 * wallx
        vdy = torch.sin(wander) + att * awdy - 1.6 * wally
        mag = torch.sqrt(vdx ** 2 + vdy ** 2).clamp(min=1e-3)
        scale = torch.clamp(mag, max=1.0) / mag
        vdx, vdy = vdx * scale, vdy * scale
        tau_r = torch.where(game > 0.5, torch.full_like(sleepy, 3.0), 0.8 - 0.9 * sleepy)   # no naps mid-game
        g = torch.sigmoid(8 * (n2 - tau_r))
        vx = speed * vdx * (1 - g); vy = speed * vdy * (1 - g)
        jump = torch.tanh(6 * (0.6 * petted + 0.4 * (n1 - 0.7).clamp(min=0) * joy - 0.35))
        jump = torch.where(game > 0.5, torch.tanh(7 * (awnear - 0.62)), jump)        # dodge-hop when it gets close
        Y[:, t] = torch.stack([vx, vy, 2 * g - 1, jump], 1)
        # integrate the toy world with the teacher's motion + heading dynamics
        ang = torch.atan2(vdy, vdx)
        dang = torch.remainder(ang - theta + math.pi, 2 * math.pi) - math.pi
        theta = theta + (2.2 * n1 + 0.8 * dang) * dt
        px = (px + vx * dt * 0.08).clamp(0, 1); py = (py + vy * dt * 0.08).clamp(0, 1)
    return X, Y, dts

wiring = AutoNCP(UNITS, OUT, sparsity_level=0.5, seed=22222)
model = CfC(IN, wiring, batch_first=True, return_sequences=True)
cell = model.rnn_cell

def run(X, D):
    B, T, _ = X.shape
    h = torch.zeros(B, cell.state_size)
    outs = []
    for t in range(T):
        o, h = cell(X[:, t], h, D[:, t:t + 1])
        outs.append(o)
    return torch.stack(outs, 1)

dense = sum(p.numel() for p in model.parameters() if p.requires_grad)
mask_nz = 0
for name, mod in model.named_modules():
    if hasattr(mod, "sparsity_mask") and mod.sparsity_mask is not None:
        mask_nz += 2 * int(mod.sparsity_mask.sum().item())  # ff1 + ff2 effective weights
print("trainable params (dense storage):", dense, flush=True)

steps = int(sys.argv[1]) if len(sys.argv) > 1 else 1500
opt = torch.optim.Adam(model.parameters(), lr=4e-3)
sched = torch.optim.lr_scheduler.CosineAnnealingLR(opt, steps, eta_min=3e-4)
w = torch.tensor([1.0, 1.0, 0.7, 0.7])
Xv, Yv, Dv = make_batch(256, 300)
t0 = time.time()
for it in range(1, steps + 1):
    X, Y, D = make_batch(96, 160)
    out = run(X, D)
    loss = (((out - Y) ** 2) * w).mean()
    opt.zero_grad(); loss.backward()
    torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
    opt.step(); sched.step()
    if it % 50 == 0 or it == 1:
        with torch.no_grad():
            ov = run(Xv, Dv)
            vl = (((ov - Yv) ** 2) * w).mean().item()
            per = ((ov - Yv) ** 2).mean((0, 1)).tolist()
        print(f"it {it:5d} train {loss.item():.4f} val {vl:.4f} per-out {[round(p,4) for p in per]} {time.time()-t0:.0f}s", flush=True)
torch.save({"model": model.state_dict()}, sys.argv[2] if len(sys.argv) > 2 else "/tmp/omg_brain.pt")
print("saved", flush=True)
