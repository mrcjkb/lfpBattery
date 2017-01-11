classdef (Abstract) sortedFunctions < lfpBattery.composite
    %SORTEDFUNCTIONS Abstract class for storing functions of x and y with
    %different z values.
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt, January 2017
    
    properties (Access = 'protected')
        xydata; % Array of curve fits that implement the curveFitInterface
        z; % Sorted vector holding 3rd dimension of curveFit objects
    end
    properties (Abstract, Access = 'protected')
        minFuns; % Minimum number of functions permitted
    end
    methods
        function c = sortedFunctions(varargin)
            if nargin < c.minFuns
               c.minfunErr
            end
            for i = 1:numel(varargin)
               c.add(varargin{i}); 
            end
            if numel(c.xydata) < c.minFuns
                c.minfunErr
            end
        end
        function add(c, d)
            if isempty(c.xydata) % object initialization
               c.xydata = d;
               c.z = d.z;
            else
                try % if another sortedCollection is added, add all the elements of sortedCollection
                    for i = 1:numel(d.xydata)
                        c.add(d.xydata(i))
                    end
                catch
                    c.xydata = [d; c.xydata]; % append new data to beginning
                    [c.z, i, ~] = unique([d.z; c.z]); % append z to beginning and remove double occurences
                    c.xydata = c.xydata(i); % remove double occurences from fits
                    [c.z, i] = sort([c.z]); % sort z data
                    c.xydata = c.xydata(i); % rearrange fits accordingly
                end
            end
        end
        function it = createIterator(obj)
            it = lfpBattery.scIterator(obj);
        end
    end
    methods (Access = 'protected')
        function minfunErr(c)
           if c.minFuns == 1
               error('At least 1 object must be added to the collection.')
           else
               error(['At least ', num2str(c.minFuns),' objects must be added to the collection.'])
           end
        end
    end
end