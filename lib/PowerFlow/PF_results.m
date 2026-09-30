function OP = PF_results(results,param)
%==========================================================================
% Convert MATPOWER results into operating-point structs
%
% Gen(1) -> Bus 1 (GFL)
% Gen(2) -> Bus 4 (GFM / Slack)
%
% PI(1)  -> Branch 2 (Bus 2 -> Bus 3)
%==========================================================================

bus    = results.bus;
gen    = results.gen;
branch = results.branch;

%% ------------------------------------------------------------------------
% Gen(1) : GFL (Bus 1)
%% ------------------------------------------------------------------------

OP.Gen(1).V_kV      = bus(1,8) * bus(1,10);
OP.Gen(1).theta_rad = deg2rad(bus(1,9));

if strcmpi(param.Type,'PV')

    idx = find(gen(:,1)==1,1);

    OP.Gen(1).P_MW   = gen(idx,2);
    OP.Gen(1).Q_MVAr = gen(idx,3);

else % PQ

    OP.Gen(1).P_MW   = param.Pset * param.P_base / 1e6;
    OP.Gen(1).Q_MVAr = param.Qset * param.P_base / 1e6;

end

%% ------------------------------------------------------------------------
% Gen(2) : GFM / Slack (Bus 4)
%% ------------------------------------------------------------------------

idx = find(gen(:,1)==4,1);

OP.Gen(2).P_MW      = gen(idx,2);
OP.Gen(2).Q_MVAr    = gen(idx,3);
OP.Gen(2).V_kV      = bus(4,8) * bus(4,10);
OP.Gen(2).theta_rad = deg2rad(bus(4,9));

%% ------------------------------------------------------------------------
% PI(1) : Branch 2 (Bus 2 -> Bus 3)
%% ------------------------------------------------------------------------

from_bus = branch(2,1);
to_bus   = branch(2,2);

V1_mag_kV = bus(from_bus,8) * bus(from_bus,10);
V2_mag_kV = bus(to_bus,8)   * bus(to_bus,10);

th1 = deg2rad(bus(from_bus,9));
th2 = deg2rad(bus(to_bus,9));

OP.PI(1).V1_kV      = V1_mag_kV;
OP.PI(1).theta1_rad = th1;

OP.PI(1).V2_kV      = V2_mag_kV;
OP.PI(1).theta2_rad = th2;

%% Current flowing from Bus 2 -> Bus 3

P12 = branch(2,14);     % MW
Q12 = branch(2,15);     % MVAr

S12 = (P12 + 1j*Q12)*1e6;

V1 = V1_mag_kV*1e3 * exp(1j*th1);

I12 = conj(S12/V1);

OP.PI(1).I_kA        = abs(I12)/1e3;
OP.PI(1).I_angle_rad = angle(I12);

end