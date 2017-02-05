classdef nrelcFit < lfpBattery.cycleCurveFit
    %NRELCFIT creates a fit object for a woehler curve
    %according to the function
    %
    %N(DoD) = p1 * (1/DoD) * exp(p2 * (1 - 1 / DoD)));
    %
    %Used in the
    %lfpBattery package for cycle aging curves (cycles to failure vs DoD)
    %Modeled according to: A Battery Life Prediction Method for Hybrid
    %Power Applications (NREL)
    %
    %N is the number of cycles to failure at a constant depth of discharge
    %DoD.
    %
    %   d = NRELCFIT(DoD, N)
    %           --> creates a fit for the function N(DoD)
    %
    %   d = NRELCFIT(DoD, N, 'OptionName', 'OptionValue');
    %           --> custom initialization of curve fit params
    %
    %OptionName-OptionValue pairs:
    %
    %   'x0'            Initial params for fit functions.
    %                   default: zeros(3, 1)
    %
    %   x0 = [p1; p2; p3]
    %
    %
    %   'mode'          Function used for fitting curves
    %                   'lsq'           - lsqcurvefit
    %                   'fmin'          - fminsearch
    %                   'both'          - (default) a combination (lsq, then fmin)
    %
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt, December 2016
    %
    %SEE ALSO: lfpBattery.deFit lfpBattery.woehlerFit lfpBattery.cycleCurveFit lfpBattery.curveFitInterface
    
    methods
        function d = nrelcFit(DoDN, N, varargin)
            %NRELCFIT creates a fit object for a woehler curve
            %according to the function
            %
            %N(DoD) = p1 * (1/DoD) * exp(p2 * (1 - 1 / DoD)));
            %
            %Used in the
            %lfpBattery package for cycle aging curves (cycles to failure vs DoD)
            %Modeled according to: A Battery Life Prediction Method for Hybrid
            %Power Applications (NREL)
            %
            %N is the number of cycles to failure at a constant depth of discharge
            %DoD.
            %
            %   d = NRELCFIT(DoD, N)
            %           --> creates a fit for the function N(DoD)
            %
            %   d = NRELCFIT(DoD, N, 'OptionName', 'OptionValue');
            %           --> custom initialization of curve fit params
            %
            %OptionName-OptionValue pairs:
            %
            %   'x0'            Initial params for fit functions.
            %                   default: zeros(3, 1)
            %
            %   x0 = [p1; p2; p3]
            %
            %
            %   'mode'          Function used for fitting curves
            %                   'lsq'           - lsqcurvefit
            %                   'fmin'          - fminsearch
            %                   'both'          - (default) a combination (lsq, then fmin)
            numParams = 3;
            % Fit according to A Battery Life Prediction Method for Hybrid
            % Power Applications (NREL)
            f = @(x, xx) (x(2) * (1/xx) .* exp(x(1) * (1 - 1/xx)));
            d@lfpBattery.cycleCurveFit(f, numParams, DoDN, N, varargin{:});
        end
    end
    methods (Access = 'protected')
        function y = func(d, xx)
            params = d.px;
            y = params(2) * (1/xx) .* exp(params(1) * (1 - 1/xx));
        end
    end
end

