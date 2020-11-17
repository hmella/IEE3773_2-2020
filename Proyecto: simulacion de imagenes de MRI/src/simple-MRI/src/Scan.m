function metadata = Scan(sequence,varargin)

    % Default arguments
    defapi = struct(...
      'homogenize_times',      false,...
      'gyromagnetic_constant', 42.58,...  % MHz/T
      'M0',                    1.0,...    
      'T1',                    850,...    % milliseconds
      'T2',                    50,...     % milliseconds
      'object',                [],...
      'image_coordinates',     [],...     % meters
      'show',                  false,...
      'off_resonance',         [],...     % Hz
      'delta_B0',              []);       % mT/m

    % Parse inputs
    api = parseinputs(defapi,[],varargin{:});

    % Image size
    Isz = size(api.object,[1 2]);

    % T1 and T2 maps
    T1 = api.T1;
    T2 = api.T2;
    
    % Gyromagnetic constant
    gamma = api.gyromagnetic_constant;
    
    % Object positions
    P = api.image_coordinates;

    % Proton density
    PD = double(api.object);

    %% Start simulation
    % Acquisition times
    t  = sequence.timing.times;
    dt = sequence.timing.dur;

    % Objects arrays
    rf_pulses = sequence.rf_pulses;
    gradients = sequence.gradients;

    % Homogenize time and acquisition objects
    if api.homogenize_times
        [th,dth,rf_pulses_h,gradients_h] = HomogenizeTimes(t,dt,rf_pulses,gradients);
    else
        th = t;
        dth = dt;
        rf_pulses_h = rf_pulses;
        gradients_h = gradients;
    end

    % Initial condition for M(r,t)
    M0 = zeros([3 prod(Isz)]);
    M0(3,:) = api.M0;

    % Solution vector
    M = zeros([3 1 prod(Isz) numel(th)]);
    M(:,1,:,1) = M0;

    % Solve the Bloch's equations (excluding the reference frame)
    for i=1:(numel(th)-1)
      
        % Relaxation matrices
        [A_relax,B_relax] = Relaxation(dth(i),T1,T2);

        % RF pulse
        if ~isempty(rf_pulses_h{i})
            R_rf = RFRotation(rf_pulses_h{i}.angle,rf_pulses_h{i}.phase);
        else
            R_rf = 1;
        end

        % Gradients
        if ~isempty(gradients_h{i})
            % Generate rotation matrices
            if gradients_h{i}.crusher
                % If the gradient is a crusher, destroy the transversal
                % magnetization
                R_z_gr = [0 0 0; 0 0 0; 0 0 1];
            else
                dir = gradients_h{i}.dir;
                amp = gradients_h{i}.amp;
                dur = gradients_h{i}.dur;
                theta_gr = (P(:,:,1)*cos(dir) + P(:,:,2)*sin(dir))*(gamma*amp*dur);
                R_z_gr = ZRotation(theta_gr);
            end
        else
            % Do nothing
            R_z_gr = 1;
        end

        % Field inhomogeneities and off-resonance
        if ~isempty(gradients_h{i})
            theta_i = 0;
            if ~isempty(api.off_resonance)
                theta_i = theta_i + ...
                          2*pi*api.off_resonance*(1e-3*gradients_h{i}.dur);
            end
            if ~isempty(api.delta_B0)
                theta_i = theta_i + ...
                          gamma*delta_B0*gradients_h{i}.dur;
            end
            R_z_in = ZRotation(theta_i);
        else
            % Do nothing
            R_z_in = 1;
        end

        % Estimates the magnetization at the current time
%         M(:,1,:,i+1) = mtimesx(mtimesx(mtimesx(mtimesx(R_z_gr, R_z_in), R_rf), A_relax), M(:,1,:,i)) + B_relax;
        M(:,1,:,i+1) = mtimesx(R_z_gr, mtimesx(R_z_in, mtimesx(R_rf, mtimesx(A_relax, M(:,1,:,i))))) + B_relax;
        
    end

    % Reshape image
    M = reshape(permute(M,[3 1 2 4]),[Isz 3 numel(th)]);
    Mxy = squeeze(M(:,:,1,:) + 1j*M(:,:,2,:));
    
    % Show image
    if api.show
        for i=1:numel(th)
            if mod(i,1)==0
              figure(3)
              tiledlayout(2,2,'Padding','compact','TileSpacing','compact')
              nexttile(1)
              imagesc(abs(M(:,:,i+1)));
              title('M_{xy}')
              axis equal off
              nexttile(2)
              imagesc(abs(itok(M(:,:,i+1)))); caxis([0 50])
              title('M_{xy}')
              axis equal off
              nexttile([1 2])
              plot(real(diag(M(:,:,i+1)))); hold on
              plot(imag(diag(M(:,:,i+1)))); hold off
              legend('Real','Imag')
              sgtitle(sprintf('Time: %.0f msec',th(i)))
              drawnow
            end
        end
    end
    
    % Prepare outputs
    metadata = struct(...
      'times',  th,...
      'rf_pulses', {rf_pulses_h},...
      'gradients', {gradients_h},...
      'Mxy',  Mxy,...
      'Mz',   squeeze(M(:,:,3,:)));
      
  
end