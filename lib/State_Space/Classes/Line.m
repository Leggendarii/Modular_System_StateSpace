classdef Line

    properties
        ID
        Parameters
        OperatingPoints
        StateNames
    end

    methods
        function obj = Line(ID, parameters, operating_points)
            obj.ID = ID;
            obj.Parameters = parameters;
            obj.OperatingPoints = operating_points;
            obj.StateNames = obj.generateStateNames();
        end

        function symb = build(obj)

            %% Definizione simbolica variabili di stato e ingressi

            syms Wn IL_d_s IL_q_s Vin_d_s Vin_q_s Vout_d_s Vout_q_s R L Cp Iin_d_s Iin_q_s Iout_d_s Iout_q_s
            
            %% Vettore stato, algebraico e ingresso
            x = [IL_d_s; IL_q_s; Vin_d_s; Vin_q_s; Vout_d_s; Vout_q_s];
            u = [Iin_d_s; Iin_q_s; Iout_d_s; Iout_q_s];
            h = [Vin_d_s; Vin_q_s; Vout_d_s; Vout_q_s];
            params = [R; L; Cp;  Wn];  
           
            
            %% Equazioni differenziali e algebraicali non lineari 
            f1 = (Wn/L)*(-R*IL_d_s + L*IL_q_s + Vin_d_s - Vout_d_s);                      % iL_d_s
            f2 = (Wn/L)*(-L*IL_d_s - R*IL_q_s + Vin_q_s - Vout_q_s);                      % iL_q_s                        
            f3 = (Iin_d_s - IL_d_s + Cp*Vin_q_s)*Wn/Cp;                                   % vin_d_s
            f4 = (Iin_q_s - IL_q_s - Cp*Vin_d_s)*Wn/Cp;                                   % vin_q_s
            f5 = (IL_d_s - Iout_d_s + Cp*Vout_q_s)*Wn/Cp;                                 % vout_d_s
            f6 = (IL_q_s - Iout_q_s - Cp*Vout_d_s)*Wn/Cp;                                 % vout_q_s

            f = [f1; f2; f3; f4; f5; f6];
            
            %% Jacobiane classiche
            A = jacobian(f,x);
            B = jacobian(f,u);
           
            C = jacobian(h,x);
            D = jacobian(h,u);

            %% Impacchettamento modello simbolico
            symb.x = x; symb.u = u; symb.h = h; symb.params = params;
            symb.f = f;
            symb.A = A; symb.B = B; symb.C = C; symb.D = D;
            fprintf('Line %d State-Space is built.\n', obj.ID);
        end

        function [sys, residuals] = evaluate(obj, symb)

            P = obj.Parameters;
            OP = obj.OperatingPoints;

            x = symb.x; u = symb.u; params = symb.params;
            f = symb.f;
            A = symb.A; B = symb.B; C = symb.C; D = symb.D;

            %%   
            params_eq = [P.R_line/P.Z_base; P.L_line/P.L_base; (P.C_line/2)/P.C_base; P.omega_b];
            x_eq = [OP.iL_d_s; OP.iL_q_s; OP.vin_d_s; OP.vin_q_s; OP.vout_d_s; OP.vout_q_s];
            u_eq = [OP.iin_d_s; OP.iin_q_s; OP.iout_d_s; OP.iout_q_s];


            %% Equilibrium residuals
            f_eq = double(subs(f, [x; u; params], [x_eq; u_eq; params_eq]));
            residuals.differential = f_eq;
            residuals.differentialNorm2 = norm(f_eq, 2);
            residuals.differentialNormInf = norm(f_eq, inf);

            fprintf(['\nLine evaluated %d equilibrium residuals: ', ...
                '||f||_2=%.3e, ||f||_inf=%.3e\n'], ...
                obj.ID, residuals.differentialNorm2, ...
                residuals.differentialNormInf);

            %%
            A_lin = double(subs(A,[x;u;params],[x_eq;u_eq;params_eq]));
            
            B_lin = double(subs(B,[x;u;params],[x_eq;u_eq;params_eq]));
            
            C_lin = double(subs(C,[x;u;params],[x_eq;u_eq;params_eq]));
            
            D_lin = double(subs(D,[x;u;params],[x_eq;u_eq;params_eq]));
            
            
            sys = ss(A_lin, B_lin, C_lin, D_lin);
            
            sys.StateName = cellstr(obj.StateNames);
        end
        
    end
  
    methods (Access = private)

    function names = generateStateNames(obj)

        baseNames = { ...
            'IL_d_s',...
            'IL_q_s',...
            'Vin_d_s',...
            'Vin_q_s',...
            'Vout_d_s',...
            'Vout_q_s'
            };

        suffix = "_" + string(obj.ID);

        names = strcat(baseNames, suffix);

    end

end
end