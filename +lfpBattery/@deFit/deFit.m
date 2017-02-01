classdef deFit < lfpBattery.cycleCurveFit
    %DEFIT creates a fit object for a batterie's cycle life
    %according to the double exponential function
    %
    %N(DoD) = x0 + x1 * exp(-x2*DoD) + x3 * exp(-x4*DoD)
    %
    %Used in the
    %lfpBattery package for cycle aging curves (cycles to failure vs DoD
    %Modelled according to Bindner et. al. - "Lifetime Modelling of Lead
    %Acid Batteries" (Also seems to work for Li-ion curves)
    %
    %N is the number of cycles to failure at a constant depth of discharge
    %DoD.
    %
    %   d = DEFIT(DoD, N)
    %           --> creates a fit for the function N(DoD)
    %
    %   d = DEFIT(DoD, N, 'OptionName', 'OptionValue');
    %           --> custom initialization of curve fit params
    %
    %OptionName-OptionValue pairs:
    %
    %   'x0'            Initial params for fit functions.
    %                   default: zeros(5, 1)
    %
    %   x0 = [a0; a1; a2; a3; a4]
    %
    %
    %   'mode'          Function used for fitting curves
    %                   'lsq'           - lsqcurvefit
    %                   'fmin'          - fminsearch
    %                   'both'          - (default) a combination (lsq, then fmin)
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt, December 2016
    %
    %SEE ALSO: lfpBattery.woehlerFit lfpBattery.nrelcFit
    %lfpBattery.cycleCurveFit lfpBattery.curveFitInterface
    
    methods
        function d = deFit(DoDN, N, varargin)
            %DEFIT creates a fit object for a batterie's cycle life
            %according to the double exponential function
            %
            %N(DoD) = x0 + x1 * exp(-x2*DoD) + x3 * exp(-x4*DoD)
            %
            %Used in the
            %lfpBattery package for cycle aging curves (cycles to failure vs DoD
            %
            %N is the number of cycles to failure at a constant depth of discharge
            %DoD.
            %
            %   d = DEFIT(DoD, N)
            %           --> creates a fit for the function N(DoD)
            %
            %   d = DEFIT(DoD, N, 'OptionName', 'OptionValue');
            %           --> custom initialization of curve fit params
            %
            %OptionName-OptionValue pairs:
            %
            %   'x0'            Initial params for fit functions.
            %                   default: zeros(5, 1)
            %
            %   x0 = [a0; a1; a2; a3; a4]
            %
            %
            %   'mode'          Function used for fitting curves
            %                   'lsq'           - lsqcurvefit
            %                   'fmin'          - fminsearch
            %                   'both'          - (default) a combination (lsq, then fmin)
            numParams = 5;
            % Fit according to Bindner et. al. - Lifetime Modelling of Lead Acid Batteries
            % Also seems to work for Li-ion curves
            f = @(x, xx) (x(1) + x(2) * exp(-x(3) * xx) + x(4) * exp(-x(5) * xx));
            d@lfpBattery.cycleCurveFit(f, numParams, DoDN, N, varargin{:});
        end
    end
end

