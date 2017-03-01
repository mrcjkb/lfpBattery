classdef eoCalAgeModel < lfpBattery.eoAgeModel
    %EOCALAGEMODEL: Combines the event oriented age model [1] with a linear calendar age model.
    %Notifies event listeners every time SoH changes. Use this class's
    %addlistener() method to add event listeners for the SohChanged and EolReached events.
    %To simulate calendar aging, call the addCalAge() method after battery cycling in the main simulation.
    %
    %
    %[1] J. Dambrowski, S. Pichlmaier, A. Jossen - "Mathematical methods for classification of
    %    state-of-charge time series for cycle lifetime prediction".
    %
    %Syntax:
    %
    % EOCALAGEMODEL(l, cy);                        Creates an eoAgeModel object that
    %                                              updates the age of the battery whenever notified by a
    %                                              cycleCounter subclass cy with the 'NewCycle' event
    %                                              (using Matlab's implementation of the observer pattern).
    % EOCALAGEMODEL(l, cy, cfit);                  The age is calculated according to the curve fit
    %                                              specified by cfit. cfit can be a function handle
    %                                              or a woehlerFit object or a custom curve fit object
    %                                              that implements the curveFitInterface.
    % EOCALAGEMODEL(l, cy, cfit, eol);             Initializes the object with an end of life SoH
    %                                              specified by eols (must be between 0 and 1)
    % EOCALAGEMODEL(l, cy, cfit, eols, init_soh);  Initializes the SoH with init_soh (must be
    %                                              between 0 and 1)
    %
    %   cy is a cycleCounter object that is to be observed by a.
    %   l = calendar life of the battery in years
    %
    %EOCALAGEMODEL Methods:
    %
    %   eoAgeModel - Class constructor
    %   addCalAge  - Adds calendar aging if the battery was not cycled
    %
    %NOTE: Rather than using a delta DoD for the woehler curve fit, a fit
    %function handle or woehlerFit object is used. The fit is applied to each cDoD histogram value returned by the
    %cycleCounter subclass, which should lead to more precise results.
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         March 2017
    
    properties (SetAccess = 'immutable')
        L_cal; % Calendar life in s
    end
    properties (Hidden, Access = 'protected')
        cycleAge = false; % Flag to indicate whether calendar aging has occured.
    end
    
    methods
        function a = eoCalAgeModel(l, varargin)
            %EOCALAGEMODEL: Combines the event oriented age model [1] with a linear calendar age model.
            %Notifies event listeners every time SoH changes. Use this class's
            %addlistener() method to add event listeners for the SohChanged and EolReached events.
            %To simulate calendar aging, call the addCalAge() method after battery cycling  in the main simulation.
            %
            %
            %[1] J. Dambrowski, S. Pichlmaier, A. Jossen - "Mathematical methods for classification of
            %    state-of-charge time series for cycle lifetime prediction".
            %
            %Syntax:
            %
            % EOCALAGEMODEL(l, cy);                        Creates an eoAgeModel object that
            %                                              updates the age of the battery whenever notified by a
            %                                              cycleCounter subclass cy with the 'NewCycle' event
            %                                              (using Matlab's implementation of the observer pattern).
            % EOCALAGEMODEL(l, cy, cfit);                  The age is calculated according to the curve fit
            %                                              specified by cfit. cfit can be a function handle 
            %                                              or a woehlerFit object or a custom curve fit object
            %                                              that implements the curveFitInterface.
            % EOCALAGEMODEL(l, cy, cfit, eol);             Initializes the object with an end of life SoH
            %                                              specified by eols (must be between 0 and 1)
            % EOCALAGEMODEL(l, cy, cfit, eols, init_soh);  Initializes the SoH with init_soh (must be
            %                                              between 0 and 1)
            %
            %   cy is a cycleCounter object that is to be observed by a.
            %   l = calendar life of the battery in years
            %% call superclass constructor
            a = a@lfpBattery.eoAgeModel(varargin{:});
            a.L_cal = l * 31557600; % set L_cal in seconds
        end % constructor
        function addCalAge(a, dt)
            % ADDCALAGE: Adds to the battery's age using the simulation time step size
            % if the battery was not cycled in the respective time step.
            %
            % Syntax:
            %       a.ADDCALAGE(dt)
            %       ADDCALAGE(a, dt)
            %
            % Input arguments:
            %
            %   a: eoCalAgeModel object
            %   dt: simulation time step size in s
            %
            % This method should be called at runtime in every simulation
            % time step.
            if ~a.cycleAge % call only if cycle aging has not occured
                % increment age as a linear function of calendar life
                a.Ac = a.Ac + dt / a.L_cal;
            end
            a.cycleAge = false; % reset
        end % addCalAge
    end
    methods (Access = 'protected')
        % Overload addAging method to set cycleAge property to true and
        % thus prevent calendar aging from being added.
        function addAging(a, src, evt)
            addAging@lfpBattery.eoAgeModel(a, src, evt) % call superclass method
            a.cycleAge = true;
        end
    end
end