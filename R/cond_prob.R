## Function cond_prob
##
##' @title
##' Conditional probabilities of superior performance
##'
##' @description
##' This function estimates the  probabilities of superior performance within
##' environments and yields plots for better visualization.
##' All the plots are customizable, using `ggplot2`
##'
##' @details
##' Using `cond_prob()`, you can estimate the probability of a genotype being amongst the
##' selected, based on a given selection intensity in a specific environment or
##' breeding region. If we let \eqn{\Omega_k} represent the subset of superior
##' genotypes in the <i>kth</i> environment, then the probability of the <i>jth</i>
##' genotype belonging to \eqn{\Omega_k} is:
##'
##' \deqn{Pr(g_{jk} \in \Omega_k \vert y) = \frac{1}{S}\sum_{s=1}^S{I(g_{jk}^{(s)} \in \Omega \vert y)}}
##'
##' where \eqn{S} is the total number of samples, and \eqn{I(g_{jk}^{(s)} \in \Omega \vert y)}
##' is an indicator variable mapping success (1) if \eqn{g_{jk}^{(s)}} exists in \eqn{\Omega},
##' and failure (0) otherwise.
##'
##' @param data A data frame containing the observations
##' @param trait A character representing the name of the column that
##' corresponds to the analysed variable
##' @param gen A character representing the name of the column that
##' corresponds to the evaluated genotypes
##' @param env A character representing the name of the column that
##' corresponds to the environments
##' @param reg A character representing the name of the column that
##' corresponds to the regions. `NULL` otherwise (default)
##' @param extr_outs An object from the `extr_outs` function
##' @param int A number representing the selection intensity
##' (superior limit = 1)
##' @param increase Logical: `TRUE` if genotypes with higher trait values are better.
##' FALSE otherwise.
##' @param save.df A logical value indicating if the data frames with the marginal
##' probability of each genotype and the pairwise probabilities should be saved at
##' the work directory.
##' @param interactive A logical value indicating if the plots should be interactive.
##' If `TRUE`, the function loads the `plotly` package and uses the [plotly::ggplotly()]
##' command.
##' @return The function returns a list with:
##' \itemize{
##' \item \code{conds_prob} : a matrix containing the probability of superior
##' performance within environments (and regions, if available).
##' \item \code{psp_env.plot} : a heatmap representing the probability of superior
##' performance of each genotype, within each environment
##' \item \code{psp_reg.plot} : a heatmap representing the probability of superior
##' performance of each genotype, within each region. Exists only if a string is
##' provided for "reg"
##' }
##'
##' @seealso [ggplot2::ggplot()]
##'
##' @references
##'
##' Dias, K. O. G, Santos J. P. R., Krause, M. D., Piepho H. -P., Guimarães, L. J. M.,
##' Pastina, M. M., and Garcia, A. A. F. (2022). Leveraging probability concepts
##' for cultivar recommendation in multi-environment trials. <i>Theoretical and
##' Applied Genetics</i>, 133(2):443-455. https://doi.org/10.1007/s00122-022-04041-y
##'
##' @import ggplot2 dplyr
##' @importFrom utils write.csv
##' @importFrom tidyr pivot_longer
##' @importFrom tidyr separate
##' @importFrom tibble rownames_to_column
##' @importFrom rlang .data
##'
##' @export
##'
##' @examples
##' \dontrun{
##' mod = bayes_met(data = soy,
##'                 gen = c("Gen", "normal", "cauchy"),
##'                 env = c("Env", "normal", "cauchy"),
##'                 rept = NULL,
##'                 reg = list(c("Reg", "normal", "cauchy"),
##'                            c("normal", "cauchy")),
##'                 res.het = F,
##'                 sigma.dist = c("cauchy", "cauchy"),
##'                 mu.dist = c("normal", "cauchy"),
##'                 gei.dist = c("normal", "normal"),
##'                 trait = "eBLUE", hyperparam = "default",
##'                 iter = 100, cores = 4, chain = 4)
##'                 #Remember, increase the number of iterations, cores and chains
##'
##' outs = extr_outs(data = soy, trait = "eBLUE", gen = "Gen", model = mod,
##'                  effects = c('l','g','gl','m','gm'),
##'                  nenv = length(unique(soy$Env)), res.het = FALSE,
##'                  check.stan.diag = TRUE)
##'
##' conds = cond_prob(data = soy, trait = "eBLUE", gen = "Gen", env = "Env",
##'                   extr_outs = outs, reg = "Reg", int = .2,
##'                   increase = TRUE, save.df = TRUE, interactive = TRUE)
##'                   }


cond_prob = function(data, trait, gen, env, reg = NULL, extr_outs, int = .2,
                     increase = TRUE, save.df = FALSE, interactive = FALSE){

  requireNamespace('ggplot2')
  requireNamespace('dplyr')
  df = data
  data = if(any(is.na(data[,trait]))) data[-which(is.na(data[,trait])),] else data
  mod = extr_outs
  name.gen = levels(factor(data[,gen]))
  num.gen = nlevels(factor(data[,gen]))
  name.env = levels(factor(data[,env]))
  num.env = nlevels(factor(data[,env]))
  num.sim = nrow(mod$post$g)

  if(increase){
    if(!is.null(reg)){

      # # Eskridge
      #
       name.reg = levels(factor(data[,reg]))
       num.reg = nlevels(factor(data[,reg]))
      #
      # V1 = apply(matrix(mod$map$gl, num.gen, num.env,
      #                   dimnames = list(name.gen, name.env)), 1, sd)
      # V2 = apply(matrix(mod$map$gm, num.gen, num.reg,
      #                   dimnames = list(name.gen, name.reg)), 1, sd)
      # Zi = stats::quantile(mod$post$g, probs = .95)
      # Risk = mod$map$g - (Zi * V1+V2)
      # Risk = as.data.frame(Risk) %>% tibble::rownames_to_column(var = 'gen') %>%
      #   dplyr::arrange(desc(Risk))
      # Risk$gen = factor(Risk$gen, levels = Risk$gen)
      #
      # sfi = ggplot(Risk, aes(x = gen, y = Risk))+
      #   geom_segment(aes(x = gen, xend = gen, y = 0, yend = Risk), linewidth = 1)+
      #   geom_point(color = '#781c1e', size = 2)+
      #   labs(x = 'Genotypes', y = 'Safety-first Index')+
      #   theme(axis.text.x = element_text(angle = 90))

      # Probabilities of superior performance within environments

      colnames(mod$post$g) = paste0(name.gen, '_')
      colnames(mod$post$gm) = paste('Gen',rep(name.gen,  times = num.reg),
                                    'Reg',rep(name.reg,  each = num.gen), sep = '_')
      name.env.reg = sort(paste('Env',unique(data[,c(env,reg)])[,1],
                                'Reg',unique(data[,c(env,reg)])[,2], sep = '_'))
      colnames(mod$post$gl) = paste('Gen',rep(name.gen,  times = num.env),
                                    'Env',rep(name.env.reg,  each = num.gen), sep = '_')


      posgge = matrix(mod$post$g, nrow = num.sim, ncol = num.env * num.gen) + mod$post$gl
      for (i in name.reg) {
        posgge[,grep(i, do.call(rbind,strsplit(colnames(posgge),'Reg'))[,2])] =
          posgge[,grep(i, do.call(rbind,strsplit(colnames(posgge),'Reg'))[,2])] +
          matrix(mod$post$gm[,grep(i, do.call(rbind,strsplit(colnames(mod$post$gm),'Reg'))[,2])],
                 nrow = num.sim, ncol = num.gen * length(name.env.reg[grep(i, do.call(rbind,strsplit(name.env.reg,'Reg'))[,2])]))
      }

      supprob = function(vector, num.gen, int){
        ifelse(names(vector) %in%
                 names(vector[order(vector, decreasing = T)][1:ceiling(int * num.gen)]), 1, 0)
      }

      probs = lapply(
        lapply(
          apply(
            posgge, 1, function(x){
              list(matrix(x, nrow = num.gen, ncol = num.env,
                          dimnames = list(name.gen, name.env.reg)))}
          ),
          Reduce, f = '+'
        ),
        function(x){
          apply(
            x,MARGIN = 2, FUN = supprob, num.gen = num.gen, int = .2
          )}
      )

      probs = apply(do.call(rbind, probs), 2, function(x){
        tapply(x, rep(name.gen, num.sim), mean)
      })

      probs = probs * ifelse(table(data[,gen],data[,env]) != 0, 1, NA)

      env.heat = as.data.frame(probs) %>% tibble::rownames_to_column(var = 'gen') %>%
        tidyr::pivot_longer(cols = c(colnames(probs)[1]:colnames(probs)[length(colnames(probs))])) %>%
        tidyr::separate(.data$name, into = c('envir','region'), sep = '_Reg_') %>%
        dplyr::mutate(
          envir = sub('Env_',"",.data$envir)
        ) %>%
        ggplot(aes(x = .data$envir, y = reorder(.data$gen, .data$value), fill = .data$value))+
        geom_tile(colour = 'white')+
        labs(x = 'Environments', y = 'Genotypes', fill = expression(bold(Pr(g[jk] %in% Omega[k]))))+
        theme(axis.text.x = element_text(angle = 90),panel.background = element_blank(),
              legend.position = 'right', legend.direction = 'vertical')+
        scale_fill_viridis_c(direction = -1, na.value = '#D3D7DC',limits = c(0,1))

      reg.heat = as.data.frame(probs) %>% tibble::rownames_to_column(var = 'gen') %>%
        tidyr::pivot_longer(cols = c(colnames(probs)[1]:colnames(probs)[length(colnames(probs))])) %>%
        tidyr::separate(.data$name, into = c('envir','region'), sep = '_Reg_') %>%
        dplyr::group_by(.data$gen,.data$region) %>%
        dplyr::summarise(value = mean(.data$value, na.rm=T), .groups = 'drop') %>%
        ggplot(aes(x = .data$region, y = reorder(.data$gen, .data$value), fill = .data$value))+
        geom_tile(colour = 'white')+
        labs(x = 'Regions', y = 'Genotypes', fill = expression(bold(Pr(g[jm] %in% Omega[m]))))+
        theme(axis.text.x = element_text(angle = 90),panel.background = element_blank(),
              legend.position = 'right', legend.direction = 'vertical')+
        scale_fill_viridis_c(direction = -1, na.value = '#D3D7DC',limits = c(0,1))

      if(save.df){
        utils::write.csv(probs, file = paste0(getwd(),'/conds_prob.csv'), row.names = F)
      }

      if(interactive){
        env.heat = suppressWarnings(plotly::ggplotly(env.heat))
        reg.heat = suppressWarnings(plotly::ggplotly(reg.heat))
        #sfi = suppressWarnings(plotly::ggplotly(sfi))
      }

      outs = list(probs, env.heat, reg.heat)
      names(outs) = c('conds_prob', 'psp_env.plot','psp_reg.plot')

      return(outs)


    }else{

      # # Eskridge
      #
      # Vi = apply(matrix(mod$map$gl, num.gen, num.env,
      #                   dimnames = list(name.gen, name.env)), 1, sd)
      # Zi = stats::quantile(mod$post$g, probs = .95)
      # Risk = mod$map$g - (Zi * Vi)
      # Risk = as.data.frame(Risk) %>% tibble::rownames_to_column(var = 'gen') %>%
      #   dplyr::arrange(desc(Risk))
      # Risk$gen = factor(Risk$gen, levels = Risk$gen)
      #
      # sfi = ggplot(Risk, aes(x = gen, y = Risk))+
      #   geom_segment(aes(x = gen, xend = gen, y = 0, yend = Risk), linewidth = 1)+
      #   geom_point(color = '#781c1e', size = 2)+
      #   labs(x = 'Genotypes', y = 'Safety-first Index')+
      #   theme(axis.text.x = element_text(angle = 90))


      # Probability of superior performance

      colnames(mod$post$g) = paste0(name.gen, '_')
      colnames(mod$post$gl) = paste(rep(name.gen,  times = num.env),
                                    rep(name.env,  each = num.gen), sep = '_')


      posgge = matrix(mod$post$g, nrow = num.sim, ncol = num.env * num.gen) + mod$post$gl

      supprob = function(vector, num.gen, int){
        ifelse(names(vector) %in%
                 names(vector[order(vector, decreasing = T)][1:ceiling(int * num.gen)]), 1, 0)
      }

      probs = lapply(
        lapply(
          apply(
            posgge, 1, function(x){
              list(matrix(x, nrow = num.gen, ncol = num.env,
                          dimnames = list(name.gen, name.env)))}
          ),
          Reduce, f = '+'
        ),
        function(x){
          apply(
            x,MARGIN = 2, FUN = supprob, num.gen = num.gen, int = .2
          )}
      )

      probs = apply(do.call(rbind, probs), 2, function(x){
        tapply(x, rep(name.gen, num.sim), mean)
      })

      probs = probs * ifelse(table(data[,gen],data[,env]) != 0, 1, NA)

      env.heat = as.data.frame(probs) %>% tibble::rownames_to_column(var = 'gen') %>%
        tidyr::pivot_longer(cols = c(colnames(probs)[1]:colnames(probs)[length(colnames(probs))]),
                            names_to = 'envir') %>%
        ggplot(aes(x = .data$envir, y = reorder(.data$gen, .data$value), fill = .data$value))+
        geom_tile(colour = 'white')+
        labs(x = 'Environments', y = 'Genotypes', fill = expression(bold(Pr(g[jk] %in% Omega[k]))))+
        theme(axis.text.x = element_text(angle = 90),panel.background = element_blank(),
              legend.position = 'right', legend.direction = 'vertical')+
        scale_fill_viridis_c(direction = -1, na.value = '#D3D7DC',limits = c(0,1))


      if(save.df){
        utils::write.csv(probs, file = paste0(getwd(),'/conds_prob.csv'), row.names = F)
      }

      if(interactive){
        requireNamespace('plotly')
        env.heat = suppressWarnings(plotly::ggplotly(env.heat))
        #sfi = suppressWarnings(plotly::ggplotly(sfi))
      }

      outs = list(probs, env.heat)
      names(outs) = c('conds_prob', 'psp_env.plot')

      return(outs)
    }
  }else{

  if(!is.null(reg)){

    # Eskridge

     name.reg = levels(factor(data[,reg]))
     num.reg = nlevels(factor(data[,reg]))
    #
    # V1 = apply(matrix(mod$map$gl, num.gen, num.env,
    #                   dimnames = list(name.gen, name.env)), 1, sd)
    # V2 = apply(matrix(mod$map$gm, num.gen, num.reg,
    #                   dimnames = list(name.gen, name.reg)), 1, sd)
    # Zi = stats::quantile(mod$post$g, probs = .05)
    # Risk = mod$map$g - (Zi * V1+V2)
    # Risk = as.data.frame(Risk) %>% tibble::rownames_to_column(var = 'gen') %>%
    #   dplyr::arrange(desc(Risk))
    # Risk$gen = factor(Risk$gen, levels = Risk$gen)
    #
    # sfi = ggplot(Risk, aes(x = gen, y = Risk))+
    #   geom_segment(aes(x = gen, xend = gen, y = 0, yend = Risk), linewidth = 1)+
    #   geom_point(color = '#781c1e', size = 2)+
    #   labs(x = 'Genotypes', y = 'Safety-first Index')+
    #   theme(axis.text.x = element_text(angle = 90))

    # Probabiliies of superior performance within environments

    colnames(mod$post$g) = paste0(name.gen, '_')
    colnames(mod$post$gm) = paste('Gen',rep(name.gen,  times = num.reg),
                                  'Reg',rep(name.reg,  each = num.gen), sep = '_')
    name.env.reg = sort(paste('Env',unique(data[,c(env,reg)])[,1],
                              'Reg',unique(data[,c(env,reg)])[,2], sep = '_'))
    colnames(mod$post$gl) = paste('Gen',rep(name.gen,  times = num.env),
                                  'Env',rep(name.env.reg,  each = num.gen), sep = '_')


    posgge = matrix(mod$post$g, nrow = num.sim, ncol = num.env * num.gen) + mod$post$gl
    for (i in name.reg) {
      posgge[,grep(i, do.call(rbind,strsplit(colnames(posgge),'Reg'))[,2])] =
        posgge[,grep(i, do.call(rbind,strsplit(colnames(posgge),'Reg'))[,2])] +
        matrix(mod$post$gm[,grep(i, do.call(rbind,strsplit(colnames(mod$post$gm),'Reg'))[,2])],
               nrow = num.sim, ncol = num.gen * length(name.env.reg[grep(i, do.call(rbind,strsplit(name.env.reg,'Reg'))[,2])]))
    }

   supprob = function(vector, num.gen, int){
     ifelse(names(vector) %in%
            names(vector[order(vector, decreasing = F)][1:ceiling(int * num.gen)]), 1, 0)
   }

   probs = lapply(
           lapply(
            apply(
                  posgge, 1, function(x){
                  list(matrix(x, nrow = num.gen, ncol = num.env,
                  dimnames = list(name.gen, name.env.reg)))}
                  ),
            Reduce, f = '+'
            ),
          function(x){
          apply(
            x,MARGIN = 2, FUN = supprob, num.gen = num.gen, int = .2
            )}
          )

   probs = apply(do.call(rbind, probs), 2, function(x){
                 tapply(x, rep(name.gen, num.sim), mean)
                 })

   probs = probs * ifelse(table(data[,gen],data[,env]) != 0, 1, NA)

   env.heat = as.data.frame(probs) %>% tibble::rownames_to_column(var = 'gen') %>%
     tidyr::pivot_longer(cols = c(colnames(probs)[1]:colnames(probs)[length(colnames(probs))])) %>%
     tidyr::separate(.data$name, into = c('envir','region'), sep = '_Reg_') %>%
     dplyr::mutate(
       envir = sub('Env_',"",.data$envir)
     ) %>%
     ggplot(aes(x = .data$envir, y = reorder(.data$gen, .data$value), fill = .data$value))+
     geom_tile(colour = 'white')+
     labs(x = 'Environments', y = 'Genotypes', fill = expression(bold(Pr(g[jk] %in% Omega[k]))))+
     theme(axis.text.x = element_text(angle = 90),panel.background = element_blank(),
           legend.position = 'right', legend.direction = 'vertical')+
     scale_fill_viridis_c(direction = -1, na.value = '#D3D7DC',limits = c(0,1))

   reg.heat = as.data.frame(probs) %>% tibble::rownames_to_column(var = 'gen') %>%
     tidyr::pivot_longer(cols = c(colnames(probs)[1]:colnames(probs)[length(colnames(probs))])) %>%
     tidyr::separate(.data$name, into = c('envir','region'), sep = '_Reg_') %>%
     dplyr::group_by(.data$gen,.data$region) %>%
     dplyr::summarise(value = mean(.data$valuevalue, na.rm=T), .groups = 'drop') %>%
     ggplot(aes(x = .data$region, y = reorder(.data$gen, .data$value), fill = .data$value))+
     geom_tile(colour = 'white')+
     labs(x = 'Regions', y = 'Genotypes', fill = expression(bold(Pr(g[jm] %in% Omega[m]))))+
     theme(axis.text.x = element_text(angle = 90),panel.background = element_blank(),
           legend.position = 'right', legend.direction = 'vertical')+
     scale_fill_viridis_c(direction = -1, na.value = '#D3D7DC',limits = c(0,1))

   if(save.df){
     utils::write.csv(probs, file = paste0(getwd(),'/conds_prob.csv'), row.names = F)
   }

   if(interactive){
     env.heat = suppressWarnings(plotly::ggplotly(env.heat))
     reg.heat = suppressWarnings(plotly::ggplotly(reg.heat))
     # sfi = suppressWarnings(plotly::ggplotly(sfi))
   }

   outs = list(probs, env.heat, reg.heat)
   names(outs) = c('conds_prob', 'psp_env.plot','psp_reg.plot')

   return(outs)


  }else{

    # Eskridge

    # Vi = apply(matrix(mod$map$gl, num.gen, num.env,
    #                   dimnames = list(name.gen, name.env)), 1, sd)
    # Zi = stats::quantile(mod$post$g, probs = .05)
    # Risk = mod$map$g - (Zi * Vi)
    # Risk = as.data.frame(Risk) %>% tibble::rownames_to_column(var = 'gen') %>%
    #   dplyr::arrange(desc(Risk))
    # Risk$gen = factor(Risk$gen, levels = Risk$gen)
    #
    # sfi = ggplot(Risk, aes(x = gen, y = Risk))+
    #   geom_segment(aes(x = gen, xend = gen, y = 0, yend = Risk), linewidth = 1)+
    #   geom_point(color = '#781c1e', size = 2)+
    #   labs(x = 'Genotypes', y = 'Safety-first Index')+
    #   theme(axis.text.x = element_text(angle = 90))


    # Probability of superior performance

    colnames(mod$post$g) = paste0(name.gen, '_')
    colnames(mod$post$gl) = paste(rep(name.gen,  times = num.env),
                                  rep(name.env,  each = num.gen), sep = '_')


    posgge = matrix(mod$post$g, nrow = num.sim, ncol = num.env * num.gen) + mod$post$gl

    supprob = function(vector, num.gen, int){
      ifelse(names(vector) %in%
               names(vector[order(vector, decreasing = F)][1:ceiling(int * num.gen)]), 1, 0)
    }

    probs = lapply(
      lapply(
        apply(
          posgge, 1, function(x){
            list(matrix(x, nrow = num.gen, ncol = num.env,
                        dimnames = list(name.gen, name.env)))}
        ),
        Reduce, f = '+'
      ),
      function(x){
        apply(
          x,MARGIN = 2, FUN = supprob, num.gen = num.gen, int = .2
        )}
    )

    probs = apply(do.call(rbind, probs), 2, function(x){
      tapply(x, rep(name.gen, num.sim), mean)
    })

    probs = probs * ifelse(table(data[,gen],data[,env]) != 0, 1, NA)

    env.heat = as.data.frame(probs) %>% tibble::rownames_to_column(var = 'gen') %>%
      tidyr::pivot_longer(cols = c(colnames(probs)[1]:colnames(probs)[length(colnames(probs))]),
                  names_to = 'envir') %>%
      ggplot(aes(x = .data$envir, y = reorder(.data$gen, .data$value), fill = .data$value))+
      geom_tile(colour = 'white')+
      labs(x = 'Environments', y = 'Genotypes', fill = expression(bold(Pr(g[jk] %in% Omega[k]))))+
      theme(axis.text.x = element_text(angle = 90),panel.background = element_blank(),
            legend.position = 'right', legend.direction = 'vertical')+
      scale_fill_viridis_c(direction = -1, na.value = '#D3D7DC',limits = c(0,1))


    if(save.df){
      utils::write.csv(probs, file = paste0(getwd(),'/conds_prob.csv'), row.names = F)
    }

    if(interactive){
      requireNamespace('plotly')
      env.heat = suppressWarnings(plotly::ggplotly(env.heat))
      # sfi = suppressWarnings(plotly::ggplotly(sfi))
    }

    outs = list(probs, env.heat)
    names(outs) = c('conds_prob', 'psp_env.plot')

    return(outs)
  }
  }

}

