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
    %NOTE: Rather than using a delta DoD for the woehler curve fit, a fit
    %function handle or woehlerFit object is used. The fit is applied to each cDoD histogram value returned by the
    %cycleCounter subclass, which should lead to more precise results.
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt, December 2016
    
    properties (Hidden, GetAccess = 'protected')
        wFit; % Woehler curve fit
    end
    
    methods
        function a = eoAgeModel(cy, fit)
            % EOAGEMODEL(cy, fit) creates an eoAgeModel event listener that
            % updates the age of the battery whenever notified by a
            % cycleCounter subclass cy with the 'NewCycle' event. The age
            % is calculated according to the woehler curve fit specified by
            % fit. fit can be a function handle or a woehlerFit object.
            addlistener(cy, 'NewCycle', @a.addAging);
            if nargin == 2
                a.wFit = fit;
            else
                warning('age model does not contain a woehler curve fit. Aging will not occur until one is added.')
                a.wFit = @(x) inf; % dividing by inf returns zero
            end
        end
        % setters
        function set.wFit(a, fit)
            if ~isa(fit, 'function_handle') && ~isa(fit, 'woehlerFit')
                error('fit must be a function_handle or a woehlerFit')
            end
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

