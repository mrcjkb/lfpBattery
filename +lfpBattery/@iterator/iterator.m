classdef (Abstract) iterator < handle
   %ITERATOR Abstract Class for iterator design pattern
   
   properties (SetAccess = 'immutable', GetAccess = 'protected', Hidden = true)
      collection;  % The elements the iterator traverses through
   end
   properties (Access = 'protected', Hidden = true)
      ind;  % index of collection's next item
   end
   methods
       function i = iterator(c)
          i.collection = c;
       end
   end
   methods (Abstract)
      obj = next(i); % Returns next object.
      tf = hasNext(i); % Returns true if iterator has another object to return
      reset(i); % Resets the iterator to first object
   end
end
