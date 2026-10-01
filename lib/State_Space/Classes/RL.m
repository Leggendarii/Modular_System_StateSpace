classdef RL
    properties
        ID
        Parameters
        OperatingPoints
        StateNames
    end

    methods

        function obj = RL(ID, parameters, operating_points)
            obj.ID = ID;
            obj.Parameters = parameters;
            obj.OperatingPoints = operating_points;
            obj.StateNames = obj.generateStateNames();
        end

        function symb = build(obj)

            %% Symbolic variables
            syms Wn IL_d_s IL_q_s Vin_d_s Vin_q_s Vout_d_s Vout_q_s R L

            %% State, input and output vectors
            x = [IL_d_s; IL_q_s];
            u = [Vin_d_s; Vin_q_s; Vout_d_s; Vout_q_s];
            h = [IL_d_s; IL_q_s];
            params = [R; L; Wn];

            %% Differential equations
            f1 = (Wn/L)*(-R*IL_d_s + L*IL_q_s + Vin_d_s - Vout_d_s);
            f2 = (Wn/L)*(-L*IL_d_s - R*IL_q_s + Vin_q_s - Vout_q_s);

            f = [f1; f2];

            %% Jacobians
            A = jacobian(f,x);
            B = jacobian(f,u);

            C = jacobian(h,x);
            D = jacobian(h,u);

            %% Pack symbolic model
            symb.x = x;
            symb.u = u;
            symb.h = h;
            symb.params = params;

            symb.f = f;

            symb.A = A;
            symb.B = B;
            symb.C = C;
            symb.D = D;

            fprintf('RL %d State-Space is built.\n', obj.ID);

        end

        function [sys,residuals] = evaluate(obj,symb)

            P = obj.Parameters;
            OP = obj.OperatingPoints;

            x = symb.x;
            u = symb.u;
            params = symb.params;

            f = symb.f;

            A = symb.A;
            B = symb.B;
            C = symb.C;
            D = symb.D;

            %% Parameters
            params_eq = [P.R; P.L; P.omega_b];

            %% Equilibrium states
            x_eq = [OP.iL_d_s; OP.iL_q_s];

            %% Equilibrium inputs
            u_eq = [OP.vin_d_s; OP.vin_q_s; OP.vout_d_s; OP.vout_q_s];

            %% Equilibrium residuals
            f_eq = double(subs(f,[x;u;params],[x_eq;u_eq;params_eq]));

            residuals.differential = f_eq;
            residuals.differentialNorm2 = norm(f_eq,2);
            residuals.differentialNormInf = norm(f_eq,inf);

            fprintf(['\nRL %d equilibrium residuals: ', ...
                     '||f||_2 = %.3e, ||f||_inf = %.3e\n'], ...
                     obj.ID, ...
                     residuals.differentialNorm2, ...
                     residuals.differentialNormInf);

            %% Linearization
            A_lin = double(subs(A,[x;u;params],[x_eq;u_eq;params_eq]));
            B_lin = double(subs(B,[x;u;params],[x_eq;u_eq;params_eq]));
            C_lin = double(subs(C,[x;u;params],[x_eq;u_eq;params_eq]));
            D_lin = double(subs(D,[x;u;params],[x_eq;u_eq;params_eq]));

            %% State-space model
            sys = ss(A_lin,B_lin,C_lin,D_lin);

            sys.StateName = cellstr(obj.StateNames);

        end

    end

    methods (Access = private)

        function names = generateStateNames(obj)

            baseNames = { ...
                'RL.IL_d',...
                'RL.IL_q' ...
                };

            suffix = "_" + string(obj.ID);

            names = strcat(baseNames,suffix);

        end

    end

end