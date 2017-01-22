classdef Stack < handle
% STACK: Matlab implementation of the java.util.Stack class.
% 
% Syntax: s = STACK; % creates an empty stack.
%
% STACK Methods:
%
% empty     - Tests if this Stack is empty.
% isempty   - Same as empty (Overloads the built-in isempty function).
% peek      - Looks at the object at the top of this Stack without removing
%             it from the Stack.
% pop       - Removes the object at the top of this Stack and returns that
%             object as the value of this function.
% push      - Pushes an item onto the top of this Stack.
% search    - Retruns the 1-based position where an object is on the Stack.
%
% Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
%          January 2017

    properties %(Access = private)
        storage = cell(1e3, 1); % Cell array to store the data in
        idx = uint32(0); % Index of the top of the stack 
    end
    
    methods
        function tf = empty(s)
            % EMPTY: Tests if this stack s is empty.
            % Returns true if the Stack is empty, otherwise false.
            %
            % Syntax: tf = s.EMPTY;
            %         tf = EMPTY(s);
            tf = ~logical(s.idx); % empty if idx == 0
        end
        function tf = isempty(s)
            % ISEMPTY: Tests if this Stack s is empty. Overloads the
            % built-in isempty function.
            % Returns true if the Stack is empty, otherwise false.
            %
            % Syntax: tf = s.ISEMPTY;
            %         tf = ISEMPTY(s);
            tf = s.empty;
        end
        function obj = peek(s)
            % PEEK: Looks at the object at the top of the Stack s without
            % removing it from the Stack.
            %
            % Syntax: obj = s.PEEK;
            %         obj = PEEK(s);
            s.emptyStackException
            obj = s.storage{s.idx};
        end
        function obj = pop(s)
            % POP: Removes the object at the top of this Stack s and
            % returns that object as the value of this function.
            %
            % Syntax: obj = s.POP;
            %         obj = POP(s);
            obj = s.peek;
            s.idx = s.idx - 1; 
        end
        function push(s, obj)
            % PUSH: Pushes an item obj onto the top of this Stack s.
            % This has exactly the same effect as s.addElement(obj).
            %
            % Syntax: s.PUSH(obj)
            %         PUSH(s, obj)
            s.idx = s.idx + 1;
            s.storage{s.idx} = obj;
        end
        function addElement(s, obj)
            % ADDELEMENT: Pushes an item obj onto the top of this Stack s.
            % This has exactly the same effect as s.push(obj).
            %
            % Syntax: s.ADDELEMENT(obj)
            %         ADDELEMENT(s, obj)
            s.push(obj);
        end
        function i = search(s, o)
            % SEARCH: Retruns the 1-based position where an object is on the Stack.
            % If the object  occurs as an item in this Stack, this method returns 
            % the distance from the top of the Stack of the occurrence nearest the
            % top of the Stack; the topmost item on the Stack is considered to be 
            % at distance 1. The isequal method is used to compare o to the items in
            % this Stack.
            %
            % Syntax: i = s.SEARCH(o);
            %         i = SEARCH(s, o);
            %
            % Input arguments:
            %   s - The stack to be searched.
            %   o - The desired object.
            %
            % Output:
            %   i - The 1-based position from the top of the Stack where the object
            %       is located; the return value -1 indicates that the object is
            %       not on the Stack.
            i = s.idx - find(cellfun(@(x) isequal(x, o), s.storage(1:s.idx)), 1, 'last') + 1;
            if isempty(i)
                i = -1;
            end
        end
        function disp(s)
            if s.empty
                disp('Empty <a href = "matlab:doc lfpBattery.stack">stack</a>.');
            else
                if s.idx == 1
                    temp = ' object.';
                else
                    temp = ' objects.';
                end
                disp(['<a href = "matlab:doc lfpBattery.stack">stack</a> holding ',...
                    num2str(s.idx), temp]);
            end
        end     
    end
    methods (Access = 'protected')
        function emptyStackException(s)
            % EMPTYSTACKEXCEPTION: Checks if the stack is empty and returns
            % an error if so.
            if s.empty
                error('Attempted to access an empty stack.')
            end
        end
    end
end