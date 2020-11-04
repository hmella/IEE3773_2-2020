function R_rf = RFRotation(alpha,phi)

R_rf = ZRotation(phi)*XRotation(alpha)*ZRotation(-phi);

end

