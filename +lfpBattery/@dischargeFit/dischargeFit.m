classdef dischargeFit < lfpBattery.curveFitInterface
    %DISCHARGEFIT: Uses Levenberg-Marquardt algorithm to fit a
    %discharge curve of a lithium-ion battery in three parts:
    %1: exponential drop at the beginning of the discharge curve
    %2: according to the nernst-equation
    %3: exponential drop at the end of the discharge curve
    %
    %Syntax:
    %   d = dischargeFit(V, C_dis, I, T);
    %           --> initialization of curve fit params with zeros
    %
    %   d = dischargeFit(V, C_dis, I, T, 'OptionName', 'OptionValue');
    %           --> custom initialization of curve fit params
    %
    %Input arguments:
    %   V:              Voltage (V) = f(C_dis) (from data sheet)
    %   C_dis:          Discharge capacity (Ah) (from data sheet)
    %   I:              Current (A) at which curve was measured
    %   T:              Temperature (K) at which curve was mearured
    %
    %OptionName-OptionValue pairs:
    %
    %   'x0'            Initial params for fit functions.
    %                   default: zeros(8, 1)
    %
    %   x0 = [E0; Ea; Eb; x0; v0; delta; Aex; Bex] with:
    %
    %   E0, Ea, Eb:     Parameters for Nernst fit (initial estimations)
    %   x0, v0, delta:  Parameters for fit of exponential drop at
    %                   the beginning of the curve (initial estimations)
    %   Aex, Bex:       Parameters for fit of exponential drop at
    %                   the end of the curve (initial estimations)
    %
    %   'mode'          Function used for fitting curves
    %                   'lsq' (default) - lsqcurvefit
    %                   'fmin'          - fminsearch
    %                   'both'          - a combination (lsq, then fmin)
    %
    %
    % DISCHARGEFIT Methods:
    %   plotResults - plots the fitted curve.
    %
    % DISCHARGEFIT Indexing:
    %       In order to retrieve the fit for a given value, use subsref
    %   indexing with (), e.g. y = cF(x);
    %
    % Authors:  Marc Jakobi, Festus Anyangbe, Marc Schmidt,
    % December 2016
    
    properties (Dependent)
        x;  % 3 fit parameters for f
        xs; % 3 fit parameters for fs
        xe; % 2 fit parameters for fe
    end
    properties (Dependent, SetAccess = 'protected')
        dV_mean; % mean difference in voltage between fit and raw data
        dV_max; % max difference in voltage between fit and raw data
    end
    properties (Dependent, Hidden, Access = 'protected')
       Cd_raw; % x data (raw discharge capacity) of initial fit curve
    end
    properties (Hidden, GetAccess = 'protected', SetAccess = 'immutable')
        Cdmax; % maximum of discharge capacity (used for conversion between dod & C_dis)
    end
    properties (SetAccess = 'protected')
        T; % Temperature at which curve was recorded
    end
    methods
        % Constructor
        function d = dischargeFit(V, C_dis, I, Temp, varargin)
            %DISCHARGEFIT: Uses Levenberg-Marquardt algorithm to fit a
            %discharge curve of a lithium-ion battery in three parts:
            %1: exponential drop at the beginning of the discharge curve
            %2: according to the nernst-equation
            %3: exponential drop at the end of the discharge curve
            %
            %Syntax:
            %   d = dischargeFit(V, C_dis, I, T);
            %           --> initialization of curve fit params with zeros
            %
            %   d = dischargeFit(V, C_dis, I, T, 'OptionName', 'OptionValue');
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
            %                   default: zeros(8, 1)
            %
            %   x0 = [E0; Ea; Eb; x0; v0; delta; Aex; Bex] with:
            %
            %   E0, Ea, Eb:     Parameters for Nernst fit (initial estimations)
            %   x0, v0, delta:  Parameters for fit of exponential drop at
            %                   the beginning of the curve (initial estimations)
            %   Aex, Bex:       Parameters for fit of exponential drop at
            %                   the end of the curve (initial estimations)
            %
            %   'mode'          Function used for fitting curves
            %                   'lsq'           - lsqcurvefit
            %                   'fmin'          - fminsearch
            %                   'both'          - (default) a combination (lsq, then fmin)
            
            if nargin < 4
                error('Not enough input arguments')
            end
            C_dis(C_dis <= 0) = 0.01; % discharge fit not defined for zero
            cdmax = max(C_dis);
            rawx = C_dis ./ cdmax; % Conversion to depth of discharge
            rawy = V;
            f = @(x, xdata)(x(1) - (lfpBattery.const.R * Temp) ... % Nernst
                / (lfpBattery.const.z_Li * lfpBattery.const.F) ...
                * log(xdata./(1-xdata)) + x(2) * xdata + x(3) ...
                + (x(4) + (x(5) + x(4) * x(6)) * xdata) .* exp(-x(6) * xdata) ... % exponential drop at the beginning of the discharge curve
                + x(7) * exp(-x(8) * xdata)); % exponential drop at the end of the discharge curve
            x0 = zeros(8, 1);
            % Optional inputs
            p = inputParser;
            addOptional(p, 'x0', x0, @(x) (isnumeric(x) & numel(x) == 8));
            addOptional(p, 'mode', 'both');
            parse(p, varargin{:})
            varargin = [{'x0', p.Results.x0}, varargin];
            d = d@lfpBattery.curveFitInterface(f, rawx, rawy, I, varargin{:}); % Superclass constructor
            d.T = Temp;
            d.Cdmax = cdmax;
            d.xxlim = [0, cdmax];
            d.yylim = [min(V), max(V)]; % limit output to raw data
        end
        function plotResults(d, newfig, varargin)
            %PLOTRESULTS: Compares a scatter of the raw data with the fit
            %into the current figure window.
            %PLOTRESULTS(true) plots figure into a new figure window
            %PLOTRESULTS(newfig, 'OptionName', 'OptionValue') plots results
            %with additional options. Setting newfig to true plots results
            %in a new figure.
            %
            %Options:
            %   noRawData (logical) - don't scatter raw data (default: false)
            %   noFitData (logical) - don't scatter fit data (default: false)
            %   SoCx (logical)      - Scale x axis as SoC instead of discharge capacity (default: false)
            p = inputParser;
            addOptional(p, 'SoCx', false, @(x)islogical(x));
            addOptional(p, 'noRawData', false, @(x)islogical(x));
            addOptional(p, 'noFitData', false, @(x)islogical(x));
            parse(p, varargin{:})
            if nargin < 2
                newfig = false;
            end
            % Remove SoCx if it exists in varargin and pass the rest to
            % superclass
            tf = cellfun(@(s) isequal('SoCx', s), varargin);
            if any(tf)
                tf(find(tf,1) + 1) = true;
                varargin = varargin(~tf);
            end
            socx = p.Results.SoCx;
            if socx
                xf = 1;
                xl = 'SoC';
            else
                xf = d.Cdmax;
                xl = 'Discharge capacity / Ah';
            end
            % Call superclas plot method
            plotResults@lfpBattery.curveFitInterface(d, 'newfig', newfig, 'xf', xf, varargin{:});
            if newfig
                title({['rmse = ', num2str(d.rmse)]; ...
                    ['mean(\DeltaV) = ', num2str(d.dV_mean), ' V']; ...
                    ['max(\DeltaV) = ', num2str(d.dV_max), ' V']})
            end
            ylabel('Voltage / V')
            xlabel(xl)
        end
        
        %% Dependent setters:
        function set.x(d, params)
            assert(numel(params) == 3, 'Wrong number of params')
            d.px(1:3) = params(:);
            d.fit;
        end
        function set.xs(d, params)
            assert(numel(params) == 3, 'Wrong number of params')
            d.px(4:6) = params(:);
            d.fit;
        end
        function set.xe(d, params)
            assert(numel(params) == 2, 'Wrong number of params')
            d.px(7:8) = params(:);
            d.fit;
        end
        
        %% Dependent getters
        function params = get.x(d)
            params = d.px(1:3);
        end
        function params = get.xs(d)
            params = d.px(4:6);
        end
        function params = get.xe(d)
            params = d.px(7:8);
        end
        function e = get.dV_mean(d)
            e = mean(d.e_tot);
        end
        function e = get.dV_max(d)
            e = max(d.e_tot);
        end
        function c = get.Cd_raw(d)
           c = d.rawX .* d.Cdmax; 
        end
    end
    methods (Access = 'protected')
        function v = fiteval(d, C_dis)
            % Overload of curveFitInterface's fiteval function
            % conversion to DoD and limitation to 0 and 1
            DoD = lfpBattery.commons.upperlowerlim(C_dis / d.Cdmax, 0, 1);
            % limit output to raw data
            v = lfpBattery.commons.upperlowerlim(d.func(DoD), d.yylim(1), d.yylim(2));
        end
        function v = func(d, DoD)
            v = d.px(1) - (lfpBattery.const.R * d.T) ... % Nernst
                / (lfpBattery.const.z_Li * lfpBattery.const.F) ...
                * log(DoD./(1-DoD)) + d.px(2) * DoD + d.px(3) ...
                + (d.px(4) + (d.px(5) + d.px(4) * d.px(6)) * DoD) .* exp(-d.px(6) * DoD) ... % exponential drop at the beginning of the discharge curve
                + d.px(7) * exp(-d.px(8) * DoD); % exponential drop at the end of the discharge curve
        end
        % gpuCompatible methods
        % These methods are currently unsupported and may be removed in a
        % future version.
        %{
        function setsubProp(obj, fn, val)
            obj.(fn) = val;
        end
        function val = getsubProp(obj, fn)
            val = obj.(fn);
        end
        %}
    end
end

