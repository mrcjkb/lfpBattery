classdef (Abstract) curveFitInterface < handle
    %CURVEFITINTERFACE Interface for curve fitting classes
    
    properties (Dependent)
        mode; % function used for fitting ('fmin' for fminsearch or 'lsq' for lsqcurvefit)
    end
    properties (Abstract, Dependent)
       x; % parameters for fit function
    end
    properties (Dependent, SetAccess = 'protected')
        rmse;
    end
    properties (Dependent, Hidden, SetAccess = 'protected', GetAccess = 'protected')
        e_tot; % total differences
    end
    properties (Hidden, GetAccess = 'protected', SetAccess = 'protected')
        px; % parameters for fit function handle
        fmin; % true for fminsearch, false for lsqcurvefit
        xxlim  = [-inf, inf]; % upper & lower limits for x data
    end
    properties (Hidden, GetAccess = 'protected', SetAccess = 'immutable')
        f; % Fit function Handle
        rawX; % raw x data of initial fit curve
        rawY; % raw y data of initial fit curve
    end
    properties (Constant, Hidden, GetAccess = 'protected')
        sseval = @(x, fdata, ydata) sum((ydata - fdata).^2); % calculation of sum squared error
        fmsoptions = optimset('Algorithm','levenberg-marquardt', ... % fminsearch options
            'Display', 'off', ...
            'MaxFunEvals', 1e10, ... 
            'MaxIter', 1e10);
        lsqoptions = optimoptions('lsqcurvefit', 'Algorithm', 'levenberg-marquardt',... % lsqcurvefit options
            'Display', 'off', ...
            'FiniteDifferenceType', 'central', ... % should be more precise than 'forward'
            'FunctionTolerance', 1e-12, ...
            'MaxIterations', 1e10, ...
            'OptimalityTolerance', 1e-12, ...
            'StepTolerance', 1e-12, ...
            'MaxFunctionEvaluations', 1e10);
    end
    methods
        function d = curveFitInterface(f, rawx, rawy, varargin)
            x0 = zeros(100, 1);
            % Optional inputs
            p = inputParser;
            addOptional(p, 'x0', x0, @(x) isnumeric(x));
            addOptional(p, 'mode', 'both', @(x) any(validatestring(x, {'fmin', 'lsq', 'both'})));
            parse(p, varargin{:})
            % interpret varargin
            parse(p, varargin{:})
            if strcmp(p.Results.mode, 'fmin')
                fmin = 1;
            elseif strcmp(p.Results.mode, 'lsq')
                fmin = 2;
            else
                fmin = 3;
            end
            d.f = f;
            d.rawX = rawx;
            d.rawY = rawy;
            d.px = p.Results.x0;
            d.fmin = fmin;
            d.fit;
        end
        % Override of subsref (indexing) function
        function v = subsref(d, S)
            if strcmp(S.type, '()')
                if numel(S.subs) > 1
                    error('Attempted to index non-indexable object.')
                end
                sub = min(max(d.xxlim(1), S.subs{1}), d.xxlim(2));
                v = d.f(d.px, sub);
            elseif nargout == 1
                v = builtin('subsref', d, S);
            else
                builtin('subsref', d, S);
            end
        end
        
        function plotResults(d)
            %PLOTRESULTS: Compares a scatter of the raw data with the fit
            %in a figure window.
            xdata = linspace(min(d.rawX), max(d.rawX), 1000)';
            figure;
            hold on
            scatter(d.rawX, d.rawY, 'filled', 'MarkerFaceColor', lfpBattery.const.red)
            plot(xdata, d.f(d.px, xdata), 'Color', lfpBattery.const.green, ...
                'LineWidth', 2)
            legend('raw data', 'fit', 'Location', 'Best')
            title(['rmse = ', num2str(d.rmse)])
            grid on
        end
        
        %% dependent setters
        function set.mode(d, str)
            validatestring(str, {'lsq', 'fmin', 'both'});
            if ~strcmp(d.mode, str)
                if strcmp(str, 'fmin')
                    d.fmin = 1;
                elseif strcmp(str, 'lsq')
                    d.fmin = 2;
                else
                    d.fmin = 3;
                end
            end
            d.fit;
        end
        
        %% dependent getters
        function m = get.mode(d)
           if d.fmin == 1
               m = 'fmin';
           elseif d.fmin == 2
               m = 'lsq';
           else
               m = 'both';
           end
        end
        function e = get.e_tot(d)
            e = d.f(d.px, d.rawX(1:end-1)) - d.rawY(1:end-1);
        end
        function r = get.rmse(d)
            % fit errors
            r = sqrt(sum(d.e_tot.^2)); % root mean squared error
        end
    end
    
    methods (Access = 'protected')
        function d = fit(d)
            %FIT: Checks which fit mode is selected and calls the
            %respective fit function/s accordingly
            if d.fmin == 1 % fminsearch
                fun = @(x) d.sseval(x, d.f(x, d.rawX(1:end-1)), d.rawY(1:end-1));
                d.px = fminsearch(fun, d.px, d.fmsoptions);
            elseif d.fmin == 2 % lsqcurvefit
                d.px = lsqcurvefit(d.f, d.px, d.rawX(1:end-1), d.rawY(1:end-1), [], [], d.lsqoptions);
            else % both (lsq, then fmin)
                d.px = lsqcurvefit(d.f, d.px, d.rawX(1:end-1), d.rawY(1:end-1), [], [], d.lsqoptions);
                fun = @(x) d.sseval(x, d.f(x, d.rawX(1:end-1)), d.rawY(1:end-1));
                d.px = fminsearch(fun, d.px, d.fmsoptions);
            end
        end
    end
    
end

