classdef (Abstract) batteryInterface < handle
    %BATTERYINTERFACE: Abstract class / interface for creating battery
    %models.
    
    properties (SetAccess = 'immutable')
       Cn; % Nominal capacity in Ah 
    end
    properties (Dependent)
        Cbu; % Useable capacity in Ah
        socMax; % Max SoC
        socMin; % Min SoC
    end
    properties (Dependent, SetAccess = 'immutable')
        ageModel = 'on'; % Indicates whether aging model is on or off
    end
    properties (Dependent, SetAccess = 'protected')
        SoC; % State of charge [0,..,1] % MTODO make observable
        SoH; % State of health [0,..,1]
        Q; % Left over nominal battery capacity in Ah (after aging)
    end
    properties (Dependent, Hidden)
        Qbu; % Useable left over capacity (soc.*C)
    end
    properties (Hidden, SetAccess = 'protected', GetAccess = 'protected')
        soh0; % Last state of health
        cyc; % cycleCounter Object
        soc_max;
        soc_min;
        soc; % State of charge [eps,..,1] (used for calculations, because 0 is reserved)
    end
    properties (Hidden, SetAccess = 'immutable',  GetAccess = 'protected')
        ageTF = true; % Model battery aging (1/0 --> 'on'/'off')
    end
    
    methods
        function b = batteryInterface(varargin)
            Cn_default = 5; % MTODO: change default value
            %% parse optional inputs
            p = inputParser;
            % on/off switch for aging model
            addOptional(p, 'agingModel', 'on', @(x) any(validatestring(x, {'on', 'off'})));
            addOptional(p, 'Cn', Cn_default, @isnumeric)
            addOptional(p, 'socMin', 0, @isnumeric)
            addOptional(p, 'socMax', 1, @isnumeric)
            addOptional(p, 'socIni', 0, @(x) x >= 0 && x <= 1)
            parse(p, varargin{:});
            if strcmp(p.Results.agingModel, 'on')
                b.ageTF = true;
            else
                b.ageTF = false;
            end
            b.Cn = p.Results.Cn;
            b.socMin = p.Results.socMin;
            b.socMax = p.Results.socMax;
            b.soc = p.Results.socIni;
        end % constructor
        
        %% setters
        function set.socMin(b, s)
            assert(s >= 0 && s <= 1, 'socMin must be between 0 and 1')
            if s == 0
                b.soc_min = eps;
            else
                b.soc_min = s;
            end
        end
        function set.socMax(b, s)
            assert(s <= 1, 'soc_max cannot be greater than 1')
            assert(s > b.socMin, 'soc_max cannot be smaller than or equal to soc_min')
            b.soc_max = s;
        end
        function set.soc(b, s)
            if s == 0
                s = eps;
            end
            b.soc = s;
        end
        
        %% getters
        function a = get.Qbu(b) % Qbu: useable leftover capacity after aging
            a = b.SoC .* b.Q;
        end
        function b = get.SoC(b)
            if b.soc == eps
                b = 0;
            else
                b = b.soc;
            end
        end
        function a = get.SoH(b)
            if b.ageTF
                a = 0.9; % MTODO: implement aging model here
            else
                a = 1;
            end
        end
        function a = get.Q(b)
            a = b.SoH .* b.Cn; 
        end
        function a = get.Cbu(b)
            a = (b.socMax - b.socMin) .* b.Q;
        end
        function a = get.socMax(b)
           a = b.soc_max; 
        end
        function a = get.socMin(b)
            a = b.soc_min;
            if a == eps
                a = 0;
            end
        end
        function a = get.ageModel(b)
            if b.ageTF
                a = 'on';
            else
                a = 'off';
            end
        end % ageModel
    end % public methods
    
    methods (Abstract)
        b = chargeRequest(b, P);
    end % abstract methods
end

