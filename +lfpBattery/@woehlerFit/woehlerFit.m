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
        function d = woehlerFit(N, DoDN, varargin)
            %WOEHLERFIT creates a fit object for a woehler curve
            %according to the function N(DoD) = p1 * DoD ^ (-p2)
            %N is the number of cycles to failure at a constant depth of discharge
            %DoD.
            %
            %   d = WOEHLERFIT(N, DoD) 
            %           --> creates a fit for the function N(DoD)
            %
            %   d = WOEHLERFIT(N, DoD, 'OptionName', 'OptionValue');
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
            
            if nargin < 2
                error('Not enough input arguments.')
            end
            x0 = [10.^7, 1.691];
            % Optional inputs
            p = inputParser;
            addOptional(p, 'x0', x0, @(x) (isnumeric(x) & numel(x) == 2));
            addOptional(p, 'mode', 'both');
            parse(p, varargin{:})
            varargin = [{'x0', p.Results.x0}, varargin];
            % Main inputs
            rawy = DoDN;
            rawx = N;
            f = @(x, xx)(x(1).*xx.^(-x(2))); % Exponential model function 
            d = d@lfpBattery.curveFitInterface(f, rawx, rawy, varargin{:}); % Superclass constructor
            d.xxlim = [0, inf]; % set boundaries
        end
        
        function plotResults(d)
            %PLOTRESULTS: Compares a scatter of the raw data with the fit
            %in a figure window.
            plotResults@lfpBattery.curveFitInterface(d); % Call superclas plot method
            ylabel('\itDoD')
            xlabel('Cycles to failure \itN')
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

