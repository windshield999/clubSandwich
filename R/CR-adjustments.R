#---------------------------------------------
# Auxilliary functions for CR* functions
#---------------------------------------------

IH_jj_list <- function(M, X_list, XW_list) {
  Map(function(x, xw) diag(nrow = nrow(x)) - x %*% M %*% xw,
         x = X_list, xw = XW_list)
}

#---------------------------------------------
# Estimating function adjustments
#---------------------------------------------

CR0 <- function(J) NULL

CR1 <- function(J) sqrt(J / (J - 1))

CR1S <- function(J, N, p) sqrt(J * (N - 1) / ((J - 1) * (N - p)))

CR2 <- function(M_U, U_list, UW_list, Theta_list, inverse_var = FALSE) {
  
  Theta_chol <- lapply(Theta_list, chol)
  
  if (inverse_var) {
    IH_jj <- IH_jj_list(M_U, U_list, UW_list)
    G_list <- Map(function(a,b,ih) as.matrix(a %*% ih %*% b %*% t(a)), 
                     a = Theta_chol, b = Theta_list, ih = IH_jj)
  } else {
    H_jj <- Map(function(u, uw) u %*% M_U %*% uw, 
                   u = U_list, uw = UW_list)
    uwTwu <- Map(function(uw, th) uw %*% th %*% t(uw), 
                    uw = UW_list, th = Theta_list)
    MUWTWUM <- M_U %*% Reduce("+", uwTwu) %*% M_U
    G_list <- Map(function(thet, h, u, v) 
      as.matrix(v %*% (thet - h %*% thet - thet %*% t(h) + u %*% MUWTWUM %*% t(u)) %*% t(v)),
      thet = Theta_list, h = H_jj, u = U_list, v = Theta_chol)
  }
  
  Map(function(v, g) as.matrix(t(v) %*% matrix_power(g, -1/2) %*% v), 
                   v = Theta_chol, g = G_list)
}

CR3 <- function(Xp_list, XpW_list) {
  XpWX_list <- Map(function(xw, x) xw %*% x, xw = XpW_list, x = Xp_list)
  M <- chol2inv(chol(Reduce("+", XpWX_list)))
  IH_jj <- IH_jj_list(M, Xp_list, XpW_list)
  lapply(IH_jj, solve)
}

CR4 <- function(M_U, U_list, UW_list, Xp_list, XpW_list, Theta_list, inverse_var = FALSE) {
  
  if (inverse_var) {
    F_list <- Map(function(xw, x) xw %*% x, xw = XpW_list, x = Xp_list)
    UWX_list <- Map(function(uw, x) uw %*% x, uw = UW_list, x = Xp_list)
    F_chol <- lapply(F_list, chol_psd)
    G_list <- Map(function(fc, fm, uwx) fc %*% (fm - t(uwx) %*% M_U %*% uwx) %*% t(fc), 
                  fc = F_chol, fm = F_list, uwx = UWX_list)
  } else {
    F_list <- Map(function(xw, theta) xw %*% theta %*% t(xw), 
                     xw = XpW_list, theta = Theta_list)
    F_chol <- lapply(F_list, chol_psd)
    UWX_list <- Map(function(uw, x) uw %*% x, uw = UW_list, x = Xp_list)
    UWTWX_list <- Map(function(uw, xw, theta) uw %*% theta %*% t(xw), uw = UW_list, xw = XpW_list, theta = Theta_list)
    UWTWU_list <- Map(function(uw, theta) uw %*% theta %*% t(uw), uw = UW_list, theta = Theta_list)
    MUWTWUM <- M_U %*% Reduce("+", UWTWU_list) %*% M_U
    G_list <- Map(function(fc, fm, uwx, uwtwx)
      as.matrix(fc %*% (fm - t(uwx) %*% M_U %*% uwtwx - t(uwtwx) %*% M_U %*% uwx + t(uwx) %*% MUWTWUM %*% uwx) %*% t(fc)),
      fc = F_chol, fm = F_list, uwx = UWX_list, uwtwx = UWTWX_list)
  }
  
  Map(function(fc, g) as.matrix(t(fc) %*% matrix_power(g, -1/2) %*% fc), 
                   fc = F_chol, g = G_list)
}
