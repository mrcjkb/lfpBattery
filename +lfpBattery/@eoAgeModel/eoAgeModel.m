classdef eoAgeModel < lfpBattery.batteryAgeModel
    %EOAGEMODEL event oriented aging model [1]
    %Notifies event listeners every time SoH changes. Use this class's
    %addlistener() method to add event listeners for the SohChanged and EolReached events.
    %
    %[1] J. Dambrowski, S. Pichlmaier, A. Jossen - "Mathematical methods for classification of
    %    state-of-charge time series for cycle lifetime prediction".
    %
    %Syntax:
    %
    % EOAGEMODEL(cy);                        Creates an eoAgeModel object that
    %                                       updates the age of the battery whenever notified by a
    %                                       cycleCounter subclass cy with the 'NewCycle' event
    %                                       (using Matlab's implementation of the observer pattern).
    % EOAGEMODEL(cy, cfit);                  The age is calculated according to the curve fit
    %                                       specified by cfit. cfit can be a function handle
    %                                       or a woehlerFit object or a custom curve fit object
    %                                       that implements the curveFitInterface.
    % EOAGEMODEL(cy, cfit, eol);             Initializes the object with an end of life SoH
    %                                       specified by eols (must be between 0 and 1)
    % EOAGEMODEL(cy, cfit, eols, init_soh);  Initializes the SoH with init_soh (must be
    %                                       between 0 and 1)
    %
    %   cy is a cycleCounter object that is to be observed by a.
    %
    %EOAGEMODEL Methods:
    %
    %   eoAgeModel - Class constructor
    %
    %NOTE: Rather than using a delta DoD for the woehler curve fit, a fit
    %function handle or woehlerFit object is used. The fit is applied to each cDoD histogram value returned by the
    %cycleCounter subclass, which should lead to more precise results.
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         December 2016
    
    methods
        function a = eoAgeModel(cy, cfit, eols, init_soh)
            %EOAGEMODEL event oriented aging model [1]
            %Notifies event listeners every time SoH changes. Use this class's
            %addlistener() method to add event listeners for the SohChanged and EolReached events.
            %
            %[1] J. Dambrowski, S. Pichlmaier, A. Jossen - "Mathematical methods for classification of
            %    state-of-charge time series for cycle lifetime prediction".
            %
            %Syntax:
            %
            % EOAGEMODEL(cy);                        Creates an eoAgeModel object that
            %                                       updates the age of the battery whenever notified by a
            %                                       cycleCounter subclass cy with the 'NewCycle' event
            %                                       (using Matlab's implementation of the observer pattern).
            % EOAGEMODEL(cy, cfit);                  The age is calculated according to the curve fit
            %                                       specified by cfit. cfit can be a function handle 
            %                                       or a woehlerFit object or a custom curve fit object
            %                                       that implements the curveFitInterface.
            % EOAGEMODEL(cy, cfit, eol);             Initializes the object with an end of life SoH
            %                                       specified by eols (must be between 0 and 1)
            % EOAGEMODEL(cy, cfit, eols, init_soh);  Initializes the SoH with init_soh (must be
            %                                       between 0 and 1)
            %
            %   cy is a cycleCounter object that is to be observed by a.
            if nargin < 3
                eols = 0.2;
            end
            if nargin < 4
                init_soh = 1;
            end
            a = a@lfpBattery.batteryAgeModel(cy, eols, init_soh); % call superclass constructor
            if nargin > 1
                a.wFit = cfit;
            else
                warning('age model does not contain a curve fit. Aging will not occur until one is added.')
                % Set wFit to function handle that always returns inf
                % (dividing by inf returns zero)
                a.wFit = @(x) inf; 
            end
        end
    end
    
    methods (Access = 'protected')
        function addAging(a, src, ~)
            % ADDAGING adds to the battery's age every time a cycleCounter
            % object (or subclass) notifies about a new cycle.
            % The aging is calculated according to the formula:
            %
            % Ac = Ac + sum(number_of_cycles_at_DoC_i / ...
            %    number_of_cycles_to_failure_at_DoC_i)
            a.Ac = a.Ac + sum(1 ./ a.wFit(src.cDoC));
        end
    end
end