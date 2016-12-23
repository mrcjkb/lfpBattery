classdef errChks
    %@ERRCHKS Class for error checks
    
    methods (Static)
        function onezeroChk(val, valName)
            if val > 1 || val < 0
                error([valName, ' must be between 0 and 1'])
            end
        end
    end
    
end

