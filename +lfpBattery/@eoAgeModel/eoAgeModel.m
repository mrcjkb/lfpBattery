classdef eoAgeModel < lfpBattery.batteryAgeModel
    %EOAGEMODEL event oriented aging model [1]
    %Notifies event listeners every time SoH changes. Use this class's
    %addlistener() method to add event listeners for the SohChanged and EolReached events.
    %
    %[1] J. Dambrowski, S. Pichlmaier, A. Jossen - "Mathematical methods for classification of
    %    state-of-charge time series for cycle lifetime prediction".
    %
    %EOAGEMODEL Methods:
    %
    %   eoAgeModel - Class constructor
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt, December 2016
    
    properties (Hidden, GetAccess = 'protected', SetAccess = 'immutable')
        wFit; % Woehler curve fit
    end
    
    methods
        function a = eoAgeModel(cy, fit)
            % EOAGEMODEL(cy, fit) creates an eoAgeModel event listener that
            % updates the age of the battery whenever notified by a
            % cycleCounter subclass cy with the 'NewCycle' event. The age
            % is calculated according to the woehler curve fit specified by
            % fit. fit can be a function handle or a woehlerFit object.
            if ~isa(@(x) sin(x), 'function_handle') && isa(@(x) sin(x), 'woehlerFit')
                error('fit must be a function_handle or a woehlerFit')
            end
            addlistener(cy, 'NewCycle', @a.addAging);
            a.wFit = fit;
        end
    end
    
    methods (Access = 'protected')
        function a = addAging(a, src, ~)
            % ADDAGING adds to the battery's age every time a cycleCounter
            % object notifies about a new cycle.
            a.Ac = a.Ac + sum(src.cDoC ./ a.wFit(src.cDoC));
        end
    end
end

