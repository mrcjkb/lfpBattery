classdef (Abstract) batteryInterface < handle
    %BATTERYINTERFACE: Abstract class / interface for creating battery
    %models.
    
    properties
       maxIterations = uint32(1e3); % maximum number of iterations
       pTol = 1e-6; % tolerance for power iteration
       sTol = 1e-6; % tolerance for SoC limitation iteration
    end
    properties (SetAccess = 'immutable')
       Cn; % Nominal capacity in Ah 
    end
    properties (Dependent)
        Cbu; % Useable capacity in Ah
        socMax; % Max SoC
        socMin; % Min SoC
    end
    properties (Dependent, SetAccess = 'protected')
        SoH; % State of health [0,..,1]
        SoC; % State of charge [0,..,1]
        Q; % Left over nominal battery capacity in Ah (after aging)
    end
    properties (Access = 'protected')
        Cd; % Discharge capacity in Ah (Cd = 0 if SoC = 1)
    end
    properties (SetAccess = 'protected');
       V; % Resting voltage / V
       Imax = 0; % maximum current in A (determined from cell discharge curves)
    end
    properties (Access = 'protected')
        soh0; % Last state of health
        cyc; % cycleCounter Object
        soc_max;
        soc_min;
        CnMax; % maximum discharge capacity
        CnMin; % minimum discharge capacity
        slTF = false; % true/false variable for limitation of SoC in recursive iteration
        pct = uint32(0); % counter for power iteration
        sct = uint32(0); % counter for soc limiting iteration
        lastPr = 0; % last power request (for handling powerIteration through recursion)
        reH; % function handle: @gt for charging and @lt for discharging
        socLim; % SoC to limit charging/discharging to (depending on charging or discharging)
    end
    properties (SetObservable, Access = 'protected')
        soc; % State of charge (for internal handling)
    end
    methods
        function b = batteryInterface(varargin)
            Cn_default = 3.5; % MTODO: remove default value
            %% parse optional inputs
            p = inputParser;
            addOptional(p, 'Cn', Cn_default, @isnumeric)
            addOptional(p, 'socMin', 0.2, @isnumeric)
            addOptional(p, 'socMax', 1, @isnumeric)
            addOptional(p, 'socIni', 0.2, @(x) x >= 0 && x <= 1)
            parse(p, varargin{:});
            b.Cn = p.Results.Cn;
            b.socMin = p.Results.socMin;
            b.socMax = p.Results.socMax;
            b.soc = p.Results.socIni;
            b.CnMax = (1 - b.socMin) .* b.Cn;
            b.CnMin = (1 - b.socMax) .* b.Cn;
            b.Cd = (1 - b.SoC) .* b.Cn;
            b.V = 3; % MTODO: Set init voltage according to discharge capacity and nominal current
        end % constructor
        function dischargeFit(b, V, C_dis, I, Temp, varargin)
            %DISCHARGEFIT: Uses Levenberg-Marquardt algorithm to fit a
            %discharge curve of a lithium-ion battery in three parts:
            %1: exponential drop at the beginning of the discharge curve
            %2: according to the nernst-equation
            %3: exponential drop at the end of the discharge curve
            %and adds the fitted curve to the battery model b.
            %Syntax:
            %   b.dischargeFit(V, C_dis, I, T);
            %           --> initialization of curve fit params with zeros
            %
            %   b.dischargeFit(V, C_dis, I, T, 'OptionName', 'OptionValue');
            %           --> custom initialization of curve fit params
            %
            %Input arguments:
            %   V:              Voltage (V) = f(C_dis) (from data sheet)
            %   C_dis:          Discharge capacity (Ah) (from data sheet)
            %   I:              Current at which curve was measured
            %   T:              Temperature (K) at which curve was mearured
            %
            %OptionName-OptionValue pairs:
            %
            %   'x0'            Initial params for fit functions.
            %                   default: zeros(9, 1)
            %
            %   x0 = [E0; Ea; Eb; Aex; Bex; Cex; x0; v0; delta] with:
            %
            %   E0, Ea, Eb:     Parameters for Nernst fit (initial estimations)
            %   Aex, Bex, Cex:  Parameters for fit of exponential drop at
            %                   the end of the curve (initial estimations)
            %   x0, v0, delta:  Parameters for fit of exponential drop at
            %                   the beginning of the curve (initial estimations)
            %
            %   'mode'          Function used for fitting curves
            %                   'lsq'           - lsqcurvefit
            %                   'fmin'          - fminsearch
            %                   'both'          - (default) a combination (lsq, then fmin)
            
            % add a new dischargeFit object according to the input arguments
            b.adddfit(lfpBattery.dischargeFit(V, C_dis, I, Temp, varargin{:}));
        end
        %% setters
        function set.socMin(b, s)
            assert(s >= 0 && s <= 1, 'socMin must be between 0 and 1')
            if s == 0
                b.soc_min = eps;
            else
                b.soc_min = s;
            end
        end
        function set.socMax(b, s)
            assert(s <= 1, 'soc_max cannot be greater than 1')
            assert(s > b.socMin, 'soc_max cannot be smaller than or equal to soc_min')
            b.soc_max = s;
        end
        function set.maxIterations(b, n)
            b.maxIterations = uint32(max(1, n));
        end
        function set.pTol(b, tol)
            b.pTol = abs(tol);
        end
        function set.sTol(b, tol)
            b.sTol = abs(tol);
        end
        
        %% getters
        function a = get.SoH(b)
            a = 1;
            % MTODO: retrieve SoH from age model
        end
        function a = get.SoC(b)
            a = lfpBattery.commons.upperlowerlim(b.soc, 0, b.socMax);
        end
        function a = get.Q(b)
            a = b.SoH .* b.Cn; 
        end
        function a = get.Cbu(b)
            a = (b.socMax - b.socMin) .* b.Q;
        end
        function a = get.socMax(b)
           a = b.soc_max; 
        end
        function a = get.socMin(b)
            a = b.soc_min;
            if a == eps
                a = 0;
            end
        end
    end % public methods
    
    methods (Abstract)
        P = powerRequest(b, P, dt); % Method for requesting power
        adddfit(b, d); % adds a discharge curve fit.
        adddcurves(b, d); % adds a collection of discharge curves
        %ITERATEPOWER: Iteration to determine new state given a certain power.
        % The state of the battery is not changed by this method.
        % Syntax: [P, Cd, V, soc] = b.iteratePower(P, dt);
        % 
        % Input arguments: 
        % b      -   Subclass of the batteryInterface (object calling the method)
        % P      -   Requested charge or discharge power in W
        % dt     -   Simulation time step size in s
        % 
        % Output arguments:
        % P      -   Actual charge or discharge power in W
        % Cd     -   Discharge capacity of the battery in Ah
        % V      -   Resting voltage in V
        % soc    -   State of charge [0,..,1]
        [P, Cd, V, soc] = iteratePower(b, P, dt, reH, socLim, sd);
    end % abstract methods

    methods (Abstract, Access = 'protected')
        findImax(b); % determins the maximum current according to the discharge curves
    end
end

