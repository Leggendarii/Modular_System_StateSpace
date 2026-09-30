function OP = OP_Converters(PF, param)

% Base for peruniting
Sb = param.P_base;
Vb = param.V_base;
Zb = Vb^2/Sb;

% Perinitization
P = PF.P_MW/param.P_base * 1e6;
Q = PF.Q_MVAr/param.P_base * 1e6;
V = PF.V_kV/param.V_base * 1e3;

Rf1 = param.R_vsc/Zb;
Xf1 = 2*pi*param.f_base*param.L_vsc/Zb;
Bc = 2*pi*param.f_base*param.C_vsc*Zb;

Rf2 = param.R_vsc2/Zb;
Xf2 = 2*pi*param.f_base*param.L_vsc2/Zb;

% PoC Values (Converter frame)
OP.vpoc_d_c = V;
OP.vpoc_q_c = 0;
OP.iout_d_c   = P/V;
OP.iout_q_c   = -Q/V;

% Grid terminal intial conditions
OP.vin_d_c = OP.vpoc_d_c - Rf2*OP.iout_d_c + Xf2*OP.iout_q_c;
OP.vin_q_c = OP.vpoc_q_c - Xf2*OP.iout_d_c - Rf2*OP.iout_q_c;

% VSC filter (Converter frame)
OP.icf_d_c = 0;
OP.icf_q_c = Bc*V;

OP.iL_d_c = OP.iout_d_c + OP.icf_d_c;
OP.iL_q_c = OP.iout_q_c + OP.icf_q_c;

OP.vvsc_d_c = OP.vpoc_d_c + Rf1*OP.iL_d_c - Xf1*OP.iL_q_c;
OP.vvsc_q_c = OP.vpoc_q_c + Xf1*OP.iL_d_c + Rf1*OP.iL_q_c;

% Return to global frame
OP.vvsc_d_s = cos(PF.theta_rad)*OP.vvsc_d_c - sin(PF.theta_rad)*OP.vvsc_q_c;
OP.vvsc_q_s = sin(PF.theta_rad)*OP.vvsc_d_c + cos(PF.theta_rad)*OP.vvsc_q_c;

OP.vpoc_d_s = cos(PF.theta_rad)*OP.vpoc_d_c - sin(PF.theta_rad)*OP.vpoc_q_c;
OP.vpoc_q_s = sin(PF.theta_rad)*OP.vpoc_d_c + cos(PF.theta_rad)*OP.vpoc_q_c;

OP.iL_d_s = cos(PF.theta_rad)*OP.iL_d_c - sin(PF.theta_rad)*OP.iL_q_c;
OP.iL_q_s = sin(PF.theta_rad)*OP.iL_d_c + cos(PF.theta_rad)*OP.iL_q_c;

OP.iout_d_s = cos(PF.theta_rad)*OP.iout_d_c - sin(PF.theta_rad)*OP.iout_q_c;
OP.iout_q_s = sin(PF.theta_rad)*OP.iout_d_c + cos(PF.theta_rad)*OP.iout_q_c;

OP.vin_d_s = cos(PF.theta_rad)*OP.vin_d_c - sin(PF.theta_rad)*OP.vin_q_c;
OP.vin_q_s = sin(PF.theta_rad)*OP.vin_d_c + cos(PF.theta_rad)*OP.vin_q_c;

% Controller states
OP.qd = OP.vvsc_d_c;
OP.qq = OP.vvsc_q_c;

OP.flux_DC  = OP.iL_d_c;
OP.flux_PoC = OP.iL_q_c;
OP.flux_PLL = 0;
OP.w_q = OP.iL_q_c;

OP.iref_d_c = OP.flux_DC;
OP.iref_q_c = OP.flux_PoC;

% References
OP.vdc_ref  = 1;
OP.vdc_mes  = 1;
OP.vpoc_ref = OP.vpoc_d_c;
OP.pref     = P;
OP.qref = Q;

% Angle
OP.theta = PF.theta_rad;
end