classdef (Abstract) iterator < handle
   %ITERATOR Abstract Class for iterator design pattern
   %
   %ITERATOR Methods:
   %    next    - Returns next object.
   %    hasNext - Returns true if there is another object to iterate
   %              through
   %    reset   - Resets iterator to first object
   %
   %Example:
   %
   % it = obj.createIterator; % Iterators are created using an object's
   %                          % createIterator method
   % collection = []
   % while it.hasNext
   %    collection = [collection; it.next];
   % end
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
