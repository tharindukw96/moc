##### FEATURE TWEAKING######

#--- Setup ----
source("featuretweaking/libs_featuretweaking.R")
args = commandArgs(trailingOnly=TRUE)
instances = readRDS(args[1])
data.dir = args[2]
best.config = readRDS(args[3])
library(checkmate)

ktree = NULL 
obj.nams = c("dist.target", "dist.x.interest", "nr.changed", "dist.train")
rf.id = unlist(lapply(instances, function(mod) mod$learner.id == "randomforest"))

message(paste("ktree is:", ktree)) 

#--- Calculate cfexps ----
feature_tweaking = function(pred) {
  message(pred$task.id)
  assert_true(pred$learner.id == "randomforest")
  
  # Load info from folder
  path = file.path(data.dir, pred$task.id)
  # row.ids = read.delim(file.path(path, "sampled_ids.txt"), header = FALSE)[,1]
  df.raw = as.data.frame(pred$predictor$data$get.x())
  map = mlrCPO::cpoScale() %>>% mlrCPO::cpoDummyEncode()
  df = mlrCPO::applyCPO(map, df.raw)
  retraf = retrafo(df)
  state =  getCPOTrainedState(retrafo(df.raw %>>% mlrCPO::cpoScale()))  ###TODO!!!
  df = df[, !(names(df) %in% pred$predictor$data$y.names)]
  df.classes = sapply(df, class)
  
  center = state$control$center
  scale = state$control$scale
  
  # Get model
  mod = pred$predictor$model$learner.model$next.model$learner.model
  class(mod) = "randomForest"
  
  # Extract x.interests
  # flat.instances = flatten_instances(list(pred))
  x.interests = pred$sampled.rows %>>% retraf
  row.names(x.interests) = as.numeric(row.names(x.interests)) + 1L
  
  # Calculate cfexps 
  targets = predict(mod, newdata = x.interests)
  target.class = mod$classes
  rules = getRules(mod, ktree = ktree, resample = TRUE)
  class(rules)
  es.rf <- set.eSatisfactory(rules, epsiron = 0.5)
  class1.id = which(targets == target.class[1])
  class2.id = which(targets == target.class[2])
  
  if (length(class1.id) > 0) {
    res.sug.class1 = tweak(es.rf, mod, newdata = x.interests[class1.id,], 
      label.from = target.class[1], label.to = target.class[2], .dopar = TRUE)$suggest
    res.sug.class1$row_ids = row.names(res.sug.class1)
  } else {
    res.sug.class1 = NULL
  }
  
  if (length(class2.id) > 0) {
    res.sug.class2 = tweak(es.rf, mod, newdata = x.interests[class2.id,], 
      label.from = target.class[2], label.to = target.class[1], .dopar = TRUE)$suggest
    res.sug.class2$row_ids = row.names(res.sug.class2)
  } else {
    res.sug.class2 = NULL
  }
  cf = rbind(res.sug.class1, res.sug.class2)
  dup.idx = which(duplicated(cf))
  if (length(dup.idx) > 1L) {
    cf = cf[-dup.idx,]
  }
  # revert scaling 
  nam.num = names(which(pred$predictor$data$feature.types == "numerical"))
  for (nam in nam.num) {
    cf[, nam] = cf[, nam]*scale[[nam]] + center[[nam]]
  }
  
  # evaluate cfexp and revert dummy encoding
  cf = evaluate_cfexp(cf, pred, id = "tweaking", remove.dom = FALSE, data.dir = data.dir)
  # Save results
  name.file = paste("cf", "tweaking", pred$learner.id, sep = "-")
  pathtofile = file.path(path, paste(name.file, ".csv", sep = ""))
  write.csv(cf, pathtofile, row.names = FALSE)
}

res = mapply(function(pred){feature_tweaking(pred)}, 
  instances[rf.id])

