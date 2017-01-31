classdef woehlerFit < lfpBattery.curveFitInterface
    %WOEHLERFIT creates a fit object for a woehler curve
    %according to the function N(DoD) = p1 * DoD ^ (-p2)
    %
    %Used in the
    %lfpBattery package for cycle aging curves (cycles to failure vs DoD 
    %
    %N is the number of cycles to failure at a constant depth of discharge
    %DoD.
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt, December 2016
    
    properties (Dependent)
        x; % fit parameters for woehler curve
    end
    
    methods
        function d = woehlerFit(DoDN, N, varargin)
            %WOEHLERFIT creates a fit object for a cycles to failure vs. DoD curve
            %according to the function:
            %
            % N(DoD) = x0 + x1 * exp(-x2*DoD) + x3 * exp(-x4*DoD)
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
            %                   default: zeros(5, 1)
            %
            %   x0 = [a0; a1; a2; a3; a4]
            %
            %
            %   'mode'          Function used for fitting curves
            %                   'lsq'           - lsqcurvefit
            %                   'fmin'          - fminsearch
            %                   'both'          - (default) a combination (lsq, then fmin)
            
            if nargin < 2
                error('Not enough input arguments.')
            end
            x0 = zeros(5,1);
            % Optional inputs
            p = inputParser;
            addOptional(p, 'x0', x0, @(x) (isnumeric(x) & numel(x) == 2));
            addOptional(p, 'mode', 'both');
            parse(p, varargin{:})
            varargin = [{'x0', p.Results.x0}, varargin];
            % Main inputs
            rawy = DoDN;
            rawx = N;
            % Fit according to Naumann et. al. - Betriebsabhaengige
            % Kostenrechnung von Energiespeichern (not applied)
%             f = @(x, xx)(x(1).*xx.^(-x(2))); % Exponential model function
            % Fit according to A Battery Life Prediction Method for Hybrid
            % Power Applications (NREL) (not applied)
%             f = @(x, xx) (x(2).*(1./xx).*exp(x(1).*(1-1./xx)));
            % Fit according to Bindner et. al. - Lifetime Modelling of Lead Acid Batteries
            % Also seems to work for Li-ion curves (better than the above
            % two fits)
            f = @(x, xx) (x(1) + x(2) .* exp(-x(3).*xx) + x(4) .* exp(-x(5).*xx));
            d = d@lfpBattery.curveFitInterface(f, rawx, rawy, varargin{:}); % Superclass constructor
            d.xxlim = [0, inf]; % set boundaries
        end
        
        function plotResults(d)
            %PLOTRESULTS: Compares a scatter of the raw data with the fit
            %in a figure window.
            plotResults@lfpBattery.curveFitInterface(d); % Call superclas plot method
            xlabel('\itDoD')
            ylabel('Cycles to failure \itN')
        end
        %% Dependent setters
        function set.x(d, params)
            assert(numel(params) == 2, 'Wrong number of params')
            d.px = params;
            d.fit;
        end
        %% Dependet getters
        function params = get.x(d)
           params = d.px; 
        end
    end

end

