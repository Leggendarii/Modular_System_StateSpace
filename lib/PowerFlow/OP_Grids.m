function OP = OP_Grids(PF, param)

% Base for peruniting
Sb = param.P_base;
Vb = param.V_base;
Zb = Vb^2/Sb;

% Per-unit
P = PF.P_MW/param.P_base * 1e6;
Q = PF.Q_MVAr/param.P_base * 1e6;
V = PF.V_kV/param.V_base * 1e3;

Rgrid = param.R_grid/Zb;
Xgrid = 2*pi*param.f_base*param.L_grid/Zb;

% Source voltage (global frame)
OP.vg_d_s = V*cos(PF.theta_rad);
OP.vg_q_s = V*sin(PF.theta_rad);

Vg = OP.vg_d_s + 1j*OP.vg_q_s;

% Injected current from PF
Ig = conj((P + 1j*Q)/Vg);

OP.ig_d_s = real(-Ig);
OP.ig_q_s = imag(-Ig);

% PoC voltage
Zgrid = Rgrid + 1j*Xgrid;
Vpoc = Vg - Zgrid*Ig;

OP.vin_d_s = real(Vpoc);
OP.vin_q_s = imag(Vpoc);
end