function OP = OP_Grids(PF,param)

%% Per-unit quantities

P = PF.P_MW*1e6/param.P_base;
Q = PF.Q_MVAr*1e6/param.P_base;

V = PF.V_kV*1e3/param.V_base;

%% Grid impedance (already in pu)

Rgrid = param.R_grid;
Xgrid = param.L_grid;

%% Source voltage (global frame)

OP.vg_d_s = V*cos(PF.theta_rad);
OP.vg_q_s = V*sin(PF.theta_rad);

Vg = OP.vg_d_s + 1j*OP.vg_q_s;

%% Injected current from PF

Ig = conj((P + 1j*Q)/Vg);

OP.ig_d_s = real(-Ig);
OP.ig_q_s = imag(-Ig);

%% PoC voltage

Zgrid = Rgrid + 1j*Xgrid;

Vpoc = Vg - Zgrid*Ig;

OP.vin_d_s = real(Vpoc);
OP.vin_q_s = imag(Vpoc);

end