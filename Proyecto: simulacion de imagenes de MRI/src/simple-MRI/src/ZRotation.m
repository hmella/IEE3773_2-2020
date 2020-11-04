function Rz = ZRotation(theta)

if numel(theta) > 1
    Rz = zeros([3 3 numel(theta)]);
    for i=1:numel(theta)
        Rz(:,:,i) = [+cos(theta(i)), +sin(theta(i)), 0;
                     -sin(theta(i)), +cos(theta(i)), 0;
                      0, 0, 1];
    end    
else
    Rz = [+cos(theta), +sin(theta), 0;
          -sin(theta), +cos(theta), 0;
          0, 0, 1];
end
