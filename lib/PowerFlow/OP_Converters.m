function OP = OP_Converters(PF, param)

%% Per-unit quantities

P = PF.P_MW * 1e6 / param.S_nom;
Q = PF.Q_MVAr * 1e6 / param.S_nom;
V = PF.V_kV * 1e3 / param.V_base;

%% Filter parameters (already in pu)

Rf1 = param.R_vsc;
Xf1 = param.L_vsc;
Bc  = param.C_vsc;

Rf2 = param.R_vsc2;
Xf2 = param.L_vsc2;

%% PoC values (converter frame)

OP.vpoc_d_c = V;
OP.vpoc_q_c = 0;

OP.iout_d_c = P/V;
OP.iout_q_c = -Q/V;

%% Grid-side terminal

OP.vin_d_c = OP.vpoc_d_c - Rf2*OP.iout_d_c + Xf2*OP.iout_q_c;
OP.vin_q_c = OP.vpoc_q_c - Xf2*OP.iout_d_c - Rf2*OP.iout_q_c;

%% VSC filter

OP.icf_d_c = 0;
OP.icf_q_c = Bc*V;

OP.iL_d_c = OP.iout_d_c + OP.icf_d_c;
OP.iL_q_c = OP.iout_q_c + OP.icf_q_c;

OP.vvsc_d_c = OP.vpoc_d_c + Rf1*OP.iL_d_c - Xf1*OP.iL_q_c;
OP.vvsc_q_c = OP.vpoc_q_c + Xf1*OP.iL_d_c + Rf1*OP.iL_q_c;

%% Global reference frame

c = cos(PF.theta_rad);
s = sin(PF.theta_rad);

OP.vvsc_d_s = c*OP.vvsc_d_c - s*OP.vvsc_q_c;
OP.vvsc_q_s = s*OP.vvsc_d_c + c*OP.vvsc_q_c;

OP.vpoc_d_s = c*OP.vpoc_d_c - s*OP.vpoc_q_c;
OP.vpoc_q_s = s*OP.vpoc_d_c + c*OP.vpoc_q_c;

OP.iL_d_s = c*OP.iL_d_c - s*OP.iL_q_c;
OP.iL_q_s = s*OP.iL_d_c + c*OP.iL_q_c;

OP.iout_d_s = c*OP.iout_d_c - s*OP.iout_q_c;
OP.iout_q_s = s*OP.iout_d_c + c*OP.iout_q_c;

OP.vin_d_s = c*OP.vin_d_c - s*OP.vin_q_c;
OP.vin_q_s = s*OP.vin_d_c + c*OP.vin_q_c;

%% Controller states

OP.qd = OP.vvsc_d_c;
OP.qq = OP.vvsc_q_c;

OP.flux_DC  = OP.iL_d_c;
OP.flux_PoC = OP.iL_q_c;

OP.flux_PLL = 0;

OP.w_q = OP.iL_q_c;

OP.iref_d_c = OP.flux_DC;
OP.iref_q_c = OP.flux_PoC;

%% References

OP.vdc_ref = 1;
OP.vdc_mes = 1;

OP.vpoc_ref = OP.vpoc_d_c;

OP.pref = P;
OP.qref = Q;

%% Angle

OP.theta = PF.theta_rad;

end