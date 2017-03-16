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
   
   methods (Abstract)
       obj = next(it); % Returns next object.
       tf = hasNext(it); % Returns true if iterator has another object to return
       reset(it); % Resets the iterator to first object
   end
   methods
       function c = saveobj(c)
           lfpBattery.commons.warnHandleSave(c)
       end
   end
   methods (Static)
       % Overload loadobj to print handle link warning
       function b = loadobj(sb)
           b = loadobj@lfpBattery.composite(sb);
           lfpBattery.commons.warnHandleSave(b)
       end
   end
end
