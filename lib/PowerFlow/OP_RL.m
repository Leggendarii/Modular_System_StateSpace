function OP = OP_RL(PF,param)

%% Terminal voltages (pu)

Vin = PF.V1_kV*1e3/param.V_base * ...
      exp(1j*PF.theta1_rad);

Vout = PF.V2_kV*1e3/param.V_base * ...
       exp(1j*PF.theta2_rad);

%% Branch impedance (already in pu)

R = param.R;
X = param.L;

%% Branch current

I = (Vin - Vout)/(R + 1j*X);

%% Voltages

OP.vin_d_s = real(Vin);
OP.vin_q_s = imag(Vin);

OP.vout_d_s = real(Vout);
OP.vout_q_s = imag(Vout);

%% Current

OP.iL_d_s = real(I);
OP.iL_q_s = imag(I);

end