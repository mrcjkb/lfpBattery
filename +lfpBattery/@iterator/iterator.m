classdef (Abstract) iterator < handle
   %ITERATOR Abstract Class for iterator design pattern
   %
   %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
   %January 2017
   
   properties (SetAccess = 'immutable', GetAccess = 'protected', Hidden = true)
      collection;  % The elements the iterator traverses through
   end
   methods
       function it = iterator(c)
          it.collection = c;
       end
   end
   methods (Abstract)
      obj = next(it); % Returns next object.
      tf = hasNext(it); % Returns true if iterator has another object to return
      reset(it); % Resets the iterator to first object
   end
end
