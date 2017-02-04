classdef woehlerFit < lfpBattery.cycleCurveFit
    %WOEHLERFIT creates a fit object for a woehler curve
    %according to the function N(DoD) = p1 * DoD ^ (-p2)
    %
    %Used in the
    %lfpBattery package for cycle aging curves (cycles to failure vs DoD)
    %Modeled according to: Naumann et. al. - "Betriebsabhaengige
    %Kostenrechnung von Energiespeichern"
    %
    %N is the number of cycles to failure at a constant depth of discharge
    %DoD.
    %
    %   d = WOEHLERFIT(DoD, N)
    %           --> creates a fit for the function N(DoD)
    %
    %   d = WOEHLERFIT(DoD, N, 'OptionName', 'OptionValue');
    %           --> custom initialization of curve fit params
    %
    %OptionName-OptionValue pairs:
    %
    %   'x0'            Initial params for fit functions.
    %                   default: zeros(2, 1)
    %
    %   x0 = [p1; p2]
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
    %SEE ALSO: lfpBattery.deFit lfpBattery.nrelcFit lfpBattery.cycleCurveFit lfpBattery.curveFitInterface
    
    methods
        function d = woehlerFit(DoDN, N, varargin)
            %WOEHLERFIT creates a fit object for a cycles to failure vs. DoD curve
            %according to the function: 
            %
            % N(DoD) = p1 * DoD ^ (-p2)
            %
            %N is the number of cycles to failure at a constant depth of discharge
            %DoD.
            %
            %   d = WOEHLERFIT(DoD, N) 
            %           --> creates a fit for the function N(DoD)
            %
            %   d = WOEHLERFIT(DoD, N, 'OptionName', 'OptionValue');
            %           --> custom initialization of curve fit params
            %
            %OptionName-OptionValue pairs:
            %
            %   'x0'            Initial params for fit functions.
            %                   default: zeros(2, 1)
            %
            %   x0 = [p1; p2]
            %
            %
            %   'mode'          Function used for fitting curves
            %                   'lsq'           - lsqcurvefit
            %                   'fmin'          - fminsearch
            %                   'both'          - (default) a combination (lsq, then fmin)
            numParams = 2;
            % Fit according to Naumann et. al. - Betriebsabhaengige
            % Kostenrechnung von Energiespeichern (not applied)
            f = @(x, xx)(x(1) * xx.^(-x(2))); % Exponential model function
            d@lfpBattery.cycleCurveFit(f, numParams, DoDN, N, varargin{:});
        end
    end
    methods (Access = 'protected')
        function refreshFunc(d)
            d.func = @(xx)(d.px(1) * xx.^(-d.px(2)));
        end
    end
end

