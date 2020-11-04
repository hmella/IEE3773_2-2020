function [times_h,dt_h,rf_pulses_h,gradients_h] = HomogenizeTimes(times,dt,rf_pulses,gradients)

  % Homogenize times
  step = gcd(min(dt),max(dt));
  times_h = min(times):step:max(times);
  dt_h = [times_h(1) (times_h(2:end)-times_h(1:end-1))];
  
  % Add empty objects to the reference time
  rf_pulses = {[] rf_pulses{:}};
  gradients = {[] gradients{:}}; 
  
  % Homogenize
  rf_pulses_h = cell([1 numel(times_h)]);
  gradients_h = cell([1 numel(times_h)]);
  for i=2:numel(times)
      rf_pulses_h{times(i)} = rf_pulses{i};
      gradients_h{times(i)} = gradients{i};
  end
  

end

