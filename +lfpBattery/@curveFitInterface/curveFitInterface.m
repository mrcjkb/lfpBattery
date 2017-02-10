classdef (Abstract) curveFitInterface < matlab.mixin.Copyable %& lfpBattery.gpuCompatible
    %CURVEFITINTERFACE Abstract interface for curve fitting classes.
    %
    %Creates a curve fit using either the lsqcurvefit
    %method, fminsearch or both.
    %
    %d = CURVEFITINTERFACE(f, x, y, zdata); fits data to x and y
    %                                       according to the
    %                                       function specified by
    %                                       the function handle f.
    %                                       zdata (1x1) must be
    %                                       added to make the curve
    %                                       fit sortable.
    %
    %d = CURVEFITINTERFACE(f, x, y, zdata, 'OptionName', 'OptionValue')
    %                                       Fit curve with
    %                                       additional options;
    %
    %Options:
    %   x0      parameters for curve fit.
    %   mode    'lsq' for lsqcurvefit, 'fmin' for fminsearch or
    %           'both' for lsqcurvefit followed by fminsearch
    %
    %CURVEFITINTERFACE Properties:
    %   z    -   z-data of fitted curve. (i. e. the current at which the curve was recorded)
    %   mode -   function used for fitting ('fmin' for fminsearch or 'lsq' for lsqcurvefit)
    %   x    -   parameters for curve fit
    %   rmse -   root mean squared error
    %
    %CURVEFITINTERFACE Methods:
    %   plotResults   - plots the fitted curve.
    %   getnumXparams - retrieve the number of x parameters
    %
    %CURVERFITINTERFACE Indexing:
    %       In order to retrieve the fit for a given value, use subsref
    %   indexing with (), e.g. y = cF(x);
    %
    %SEE ALSO: lfpBattery.curvefitCollection, lfpBattery.dischargeCurves
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         December 2017
    
    properties (SetAccess = 'immutable')
       z; % z-data of fitted curve. (i. e. the current at which the curve was recorded)
    end
    properties (Dependent)
        mode; % function used for fitting ('fmin' for fminsearch or 'lsq' for lsqcurvefit)
    end
    properties (Abstract, Dependent)
       x; % parameters for fit function
    end
    properties (Dependent, SetAccess = 'protected')
        rmse; % root mean squared error
    end
    properties (Dependent, Hidden, SetAccess = 'protected', GetAccess = 'protected')
        e_tot; % total differences
    end
    properties (Hidden, Access = 'protected')
        px; % parameters for fit function handle
        fmin; % 1 for fminsearch, 2 for lsqcurvefit, 3 for both
        xxlim  = [-inf, inf]; % upper & lower limits for x data
        yylim = [-inf, inf]; % upper & lower limits for y data
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
        function d = curveFitInterface(f, rawx, rawy, zdata, varargin)
            %CURVEFITINTERFACE: Creates a curve fit using either the lsqcurvefit
            %method, fminsearch or both.
            %
            %d = CURVEFITINTERFACE(f, x, y, zdata); fits data to x and y
            %                                       according to the
            %                                       function specified by
            %                                       the function handle f.
            %                                       zdata (1x1) must be
            %                                       added to make the curve
            %                                       fit sortable.
            %
            %d = CURVEFITINTERFACE(f, x, y, zdata, 'OptionName', 'OptionValue')
            %                                       Fit curve with
            %                                       additional options;
            %
            %Options:
            %   x0      parameters for curve fit.
            %   mode    'lsq' for lsqcurvefit, 'fmin' for fminsearch or
            %           'both' for lsqcurvefit followed by fminsearch
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
            d.z = sum(zdata); % Converts zdata to 0 if it is empty
            d.px = p.Results.x0;
            d.fmin = fmin;
            d.fit;
        end
        % Override of subsref (indexing) function
        function v = subsref(d, S)
            if strcmp(S(1).type, '()')
                v = d.fiteval(S(1).subs{1});
            elseif nargout == 1
                v = builtin('subsref', d, S);
            else
                builtin('subsref', d, S);
            end
        end % subsref overload
        function plotResults(d, varargin)
            %PLOTRESULTS: Compares a scatter of the raw data with the fit
            %in a figure window.
            %
            %Syntax: obj.PLOTRESULTS
            %        obj.PLOTRESULTS('OptionName', 'OptionValue')
            %
            %Options:
            %   newfig (logical)    - create new figure? (default: true)
            %   xf (numeric)        - factor for x data (default: 1)
            %   yf (numeric)        - factor for y data (default: 1)
            %   noRawData (logical) - don't scatter raw data (default: false)
            %   noFitData (logical) - don't scatter fit data (default: false)
            p = inputParser;
            addOptional(p, 'newfig', true, @(x)islogical(x));
            addOptional(p, 'xf', 1, @(x)isnumeric(x));
            addOptional(p, 'yf', 1, @(x)isnumeric(x));
            addOptional(p, 'noRawData', false, @(x)islogical(x));
            addOptional(p, 'noFitData', false, @(x)islogical(x));
            parse(p, varargin{:})
            newfig = p.Results.newfig;
            xf = p.Results.xf;
            yf = p.Results.yf;
            nrd = p.Results.noRawData;
            nfd = p.Results.noFitData;
            xdata = linspace(min(d.rawX), max(d.rawX), 1000)';
            if newfig
                figure;
            end
            hold on
            if ~nrd
                scatter(xf.*d.rawX, yf.*d.rawY, 'filled', 'MarkerFaceColor', lfpBattery.const.red)
            end
            if ~nfd
                plot(xf.*xdata, yf.*d.func(xdata), 'Color', lfpBattery.const.green, ...
                    'LineWidth', 2)
            end
            if newfig
                legend('raw data', 'fit', 'Location', 'Best')
                title(['rmse = ', num2str(d.rmse)])
                grid on
            end
        end % plotResults
        function n = getnumXparams(d)
            %GETNUMXPARAMS: Returns the number of x parameters required for
            %a class that implements the curveFitInterface.
            %
            %Syntax: n = d.GETNUMXPARAMS;
            %        n = GETNUMXPARAMS(d);
            %
            %d is the class that implements the curveFitInterface and n is
            %the number of x parameters required for the curve fit.
            n = numel(d.x);
        end
        %% dependent setters
        function set.mode(d, str)
            d.setModeErrorHandler
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
            e = d.func(d.rawX(1:end-1)) - d.rawY(1:end-1);
        end
        function r = get.rmse(d)
            % fit errors
            r = sqrt(sum(d.e_tot.^2)); % root mean squared error
        end
    end
    
    methods (Access = 'protected')
        function fit(d)
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
        function v = fiteval(d, sub)
            %FITEVAL: Called by subsref if appropriate indexing for
            %retrieving fit data is used.
            % limit x data
            sub = lfpBattery.commons.upperlowerlim(sub, d.xxlim(1), d.xxlim(2));
            % limit y data
            v = lfpBattery.commons.upperlowerlim(d.func(sub), d.yylim(1), d.yylim(2));
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
    methods (Abstract, Access = 'protected')
        % Implements the function with the fitted params.
        % (Faster than using an anonymous function handle)
        y = func(d, x);
    end
    methods (Static, Access = 'protected')
        function setModeErrorHandler
            % Does nothing by default;
        end
    end
end

