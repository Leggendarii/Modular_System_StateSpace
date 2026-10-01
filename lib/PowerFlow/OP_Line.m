function OP = OP_Line(PF,param)

%% Terminal voltages (pu)

Vin  = PF.V1_kV*1e3/param.V_base * exp(1j*PF.theta1_rad);
Vout = PF.V2_kV*1e3/param.V_base * exp(1j*PF.theta2_rad);

%% PI-section parameters (already in pu)

R  = param.R_line;
L  = param.L_line;
Cp = param.C_line/2;

%% Series RL current

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