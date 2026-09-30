function OP = OP_Line(PF,param)

%% Base quantities

Vb = param.V_base;
Zb = param.Z_base;

%% Terminal voltages (pu)

Vin  = PF.V1_kV*1e3/Vb * exp(1j*PF.theta1_rad);
Vout = PF.V2_kV*1e3/Vb * exp(1j*PF.theta2_rad);

%% PI-section parameters (pu)

R  = param.R_line/Zb;
L  = param.L_line/param.L_base;
Cp = (param.C_line/2)/param.C_base;

%% Series RL current
%
% (R+jL)IL = Vin-Vout
%

IL = (Vin - Vout)/(R + 1j*L);

%% Terminal currents
Iin  = IL + 1j*Cp*Vin;
Iout = IL - 1j*Cp*Vout;

%% Voltages

OP.vin_d_s  = real(Vin);
OP.vin_q_s  = imag(Vin);

OP.vout_d_s = real(Vout);
OP.vout_q_s = imag(Vout);

%% Inductor current

OP.iL_d_s = real(IL);
OP.iL_q_s = imag(IL);

%% Input current

OP.iin_d_s = real(Iin);
OP.iin_q_s = imag(Iin);

%% Output current

OP.iout_d_s = real(Iout);
OP.iout_q_s = imag(Iout);

end