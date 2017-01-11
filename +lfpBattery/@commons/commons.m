classdef commons
    %COMMONS: Class for commonly used static functions
    
    methods (Static)
        function onezeroChk(val, valName)
            if val > 1 || val < 0
                error([valName, ' must be between 0 and 1'])
            end
        end
        function validateInterface(obj, name)
            % VALIDATEINTERFACE: Checks the superclasses to make sure the class obj subclasses
            % the superclass name
            if ~any(ismember(superclasses(obj), name))
                error('Specified object does not implement the correct interface.')
            end
        end
    end
    
end

