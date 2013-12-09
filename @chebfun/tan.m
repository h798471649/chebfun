function F = tan(F, pref)
%TAN   Tangent of a CHEBFUN.
%   TAN(F) computes the tangent of the CHEBFUN F.
%
%   TAN(F, PREF) does the same but uses the CHEBPREF object PREF when
%   computing the composition.
%
% See also ATAN, TAND.

% Copyright 2013 by The University of Oxford and The Chebfun Developers.
% See http://www.chebfun.org for Chebfun information.

% Obtain preferences:
if ( nargin == 1 )
    pref = chebpref();
end

% [TODO]:  Restore or change this once we have decided the proper behavior or
% isfinite() and defined that function.
% if ( ~isfinite(f) )
%     error('CHEBFUN:sin:inf',...
%         'SIN is not defined for functions which diverge to infinity');
% end

% Loop over the columns of F:
for k = 1:numel(F)
    % Call the compose method:
    F(k) = compose(F(k), @tan, pref);
end

end
