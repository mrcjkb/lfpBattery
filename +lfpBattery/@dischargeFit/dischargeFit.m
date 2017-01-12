classdef dischargeFit < lfpBattery.curveFitInterface
    %DISCHARGEFIT: Uses Levenberg-Marquardt algorithm to fit a
    %discharge curve of a lithium-ion battery in three parts:
    %1: exponential drop at the beginning of the discharge curve
    %2: according to the nernst-equation
    %3: exponential drop at the end of the discharge curve
    %
    %Syntax:
    %   d = dischargeFit(V, C_dis, C, T);
    %           --> initialization of curve fit params with zeros
    %
    %   d = dischargeFit(V, C_dis, C, T, 'OptionName', 'OptionValue');
    %           --> custom initialization of curve fit params
    %
    %Input arguments:
    %   V:              Voltage (V) = f(C_dis) (from data sheet)
    %   C_dis:          Discharge capacity (Ah) (from data sheet)
    %   C:              C-Rate at which curve was measured
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
    %                   'lsq' (default) - lsqcurvefit
    %                   'fmin'          - fminsearch
    %                   'both'          - a combination (lsq, then fmin)
    %
    % Authors:  Marc Jakobi, Festus Anyangbe, Marc Schmidt,
    % December 2016
    
    properties (Dependent)
        x;  % 3 fit parameters for f
        xs; % 3 fit parameters for fs
        xe; % 3 fit parameters for fe
    end
    properties (Dependent, SetAccess = 'protected')
        dV_mean; % mean difference in voltage between fit and raw data
        dV_max; % max difference in voltage between fit and raw data
    end
    properties (Dependent, Hidden, SetAccess = 'protected', GetAccess = 'protected')
       Cd_raw; % x data (raw discharge capacity) of initial fit curve
    end
    properties (Hidden, GetAccess = 'protected', SetAccess = 'immutable')
        Cdmax; % maximum of discharge capacity (used for conversion between dod & C_dis)
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
            
            if nargin < 4
                error('Not enough input arguments')
            end
            cdmax = max(C_dis);
            rawx = C_dis ./ cdmax; % Conversion to depth of discharge
            rawy = V;
            f = @(x, xdata)(x(1) - (lfpBattery.const.R .* Temp) ... % Nernst
                ./ (lfpBattery.const.z_Li .* lfpBattery.const.F) ...
                .* log(xdata./(1-xdata)) + x(2) .* xdata + x(3)) ...
                + ((x(4) + (x(5) + x(4).*x(6)) .* xdata) .* exp(-x(6) .* xdata)) ... % exponential drop at the beginning of the discharge curve
                + (x(7) .* exp(-x(8) .* xdata) + x(9)); % exponential drop at the end of the discharge curve
            x0 = zeros(9, 1);
            % Optional inputs
            p = inputParser;
            addOptional(p, 'x0', x0, @(x) (isnumeric(x) & numel(x) == 9));
            addOptional(p, 'mode', 'both');
            parse(p, varargin{:})
            varargin = [{'x0', p.Results.x0}, varargin];
            d = d@lfpBattery.curveFitInterface(f, rawx, rawy, I, varargin{:}); % Superclass constructor
            d.Cdmax = cdmax;
            d.xxlim = [0, cdmax];
            d.yylim = [min(V), max(V)]; % limit output to raw data
        end
        function v = subsref(d, S)
            if strcmp(S(1).type, '()') && numel(d) == 1
                if numel(S(1).subs) > 1
                    error('Cannot index dischargeFit')
                end
                C_dis = S(1).subs{1};
                % conversion to DoD and limitation to 0 and 1
                DoD = lfpBattery.commons.upperlowerlim(C_dis ./ d.Cdmax, 0, 1); 
                % limit output to raw data
                v = lfpBattery.commons.upperlowerlim(d.f(d.px, DoD), d.yylim(1), d.yylim(2));
            elseif nargout == 1
                v = builtin('subsref', d, S(1));
            else
                builtin('subsref', d, S(1));
            end
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
            if nargin < 2
                newfig = false;
            end
            % Call superclas plot method
            plotResults@lfpBattery.curveFitInterface(d, 'newfig', newfig, 'xf', d.Cdmax, varargin{:});
            if newfig
                title({['rmse = ', num2str(d.rmse)]; ...
                    ['mean(\DeltaV) = ', num2str(d.dV_mean), ' V']; ...
                    ['max(\DeltaV) = ', num2str(d.dV_max), ' V']})
            end
            ylabel('Voltage / V')
            xlabel('Discharge capacity / Ah')
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
            assert(numel(params) == 3, 'Wrong number of params')
            d.px(7:9) = params(:);
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
            params = d.px(7:9);
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
    
end

