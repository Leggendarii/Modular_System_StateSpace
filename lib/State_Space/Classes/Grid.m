classdef Grid

    properties
        ID
        Parameters
        OperatingPoints
        StateNames
    end

    methods
        function obj = Grid(ID, parameters, operating_points)
            obj.ID = ID;
            obj.Parameters = parameters;
            obj.OperatingPoints = operating_points;
            obj.StateNames = obj.generateStateNames();
        end

        function symb = build(obj)

            %% Definizione simbolica variabili di stato e ingressi

            syms Wn L2 R2 Ig_d_s Ig_q_s Vin_d_s Vin_q_s Vg_d_s Vg_q_s
            
            %% Vettore stato, algebraico e ingresso
            x = [Ig_d_s; Ig_q_s];
            u = [Vg_d_s; Vg_q_s; Vin_d_s; Vin_q_s];
            h = [Ig_d_s; Ig_q_s];
            params = [R2; L2; Wn];  
           
            
            %% Equazioni differenziali e algebraicali non lineari 
            f1 = (Wn/L2)*(-R2*Ig_d_s + L2*Ig_q_s + Vin_d_s - Vg_d_s);                          % ig_d_s
            f2 = (Wn/L2)*(-L2*Ig_d_s - R2*Ig_q_s + Vin_q_s - Vg_q_s);                          % ig_q_s  
            
            f = [f1; f2];
            
            %% Jacobiane classiche
            A = jacobian(f,x);
            B = jacobian(f,u);
           
            C = jacobian(h,x);
            D = jacobian(h,u);

            %% Impacchettamento modello simbolico
            symb.x = x; symb.u = u; symb.h = h; symb.params = params;
            symb.f = f;
            symb.A = A; symb.B = B; symb.C = C; symb.D = D;
            fprintf('Grid %d State-Space is built.\n', obj.ID);
        end

        function [sys, residuals] = evaluate(obj, symb)

            P = obj.Parameters;
            OP = obj.OperatingPoints;

            x = symb.x; u = symb.u; params = symb.params;
            f = symb.f;
            A = symb.A; B = symb.B; C = symb.C; D = symb.D;

            %%   
            params_eq = [P.R_grid/P.Z_base; P.L_grid/P.L_base; P.omega_b];
            x_eq = [OP.ig_d_s; OP.ig_q_s];
            u_eq = [OP.vg_d_s; OP.vg_q_s; OP.vin_d_s; OP.vin_q_s];

            %% Equilibrium residuals
            f_eq = double(subs(f, [x; u; params], [x_eq; u_eq; params_eq]));
            residuals.differential = f_eq;
            residuals.differentialNorm2 = norm(f_eq, 2);
            residuals.differentialNormInf = norm(f_eq, inf);

            fprintf(['\nGrid evaluated %d equilibrium residuals: ', ...
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
            'Ig_d_s',...
            'Ig_q_s',...
            };

        suffix = "_" + string(obj.ID);

        names = strcat(baseNames, suffix);

    end

end
end