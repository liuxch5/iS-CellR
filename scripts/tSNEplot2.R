#!/usr/bin/env Rscript

# Plot tSNE1 and tSNE2 using ggplot2,
if(isS4(scObject$val) || "defLabels" %in% isolate(input$clustLabels) || input$changeLabels)
{
  ################## for Custom labels ################
  if("customLabels" %in% isolate(input$clustLabels)) {
    cluster.ids <- as.character(unlist(ClusterLabInfo$val[,1]))#, decreasing = FALSE)#c("CD4", "Bcells", "CD8cells",
    new.cluster.ids <- as.character(unlist(ClusterLabInfo$val[,2]))#c("CD4", "Bcells", "CD8cells", 
    if(input$changeLabels){
      #scObject$val <- RenameIdents(scObject$val, new.cluster.ids)
      Idents(scObject$val) <- plyr::mapvalues(x = Idents(scObject$val), from = cluster.ids, to = new.cluster.ids)
    }
    CInfo <- cbind(cluster.ids,new.cluster.ids)
    ClusterLabInfo$val <- CInfo
  }

  if("defLabels" %in% isolate(input$clustLabels)) {
    if(!is.null(dfcluster.ids$val)){
      new.cluster.ids <- as.character(unlist(ClusterLabInfo$val[,2]))
      current.ids <- as.character(unlist(ClusterLabInfo$val[,1]))#, decreasing = FALSE)#c("CD4", "Bcells", "CD8cells",
      #scObject$val <- RenameIdents(scObject$val, current.ids)
      Idents(scObject$val) <- plyr::mapvalues(x = Idents(scObject$val), from = new.cluster.ids, to = current.ids)
    } else {
      new.cluster.ids = ""
      current.ids <- sort(as.character(unique(Idents(scObject$val))), decreasing = FALSE)
    }
    cluster.ids <- current.ids
    CInfo <- cbind(cluster.ids,new.cluster.ids)
    ClusterLabInfo$val <- CInfo 
    dfcluster.ids$val <- cluster.ids      
  }

########### tSNE plot ggplot2 
# Create data frame of clusters computed by Seurat
df.cluster <- data.frame(Cell = names(Idents(object = scObject$val)), Cluster = Idents(object = scObject$val))
    
# Create data frame of tSNE compute by Seurat
df.umap <- data.frame(Embeddings(object = scObject$val, reduction = "umap"))
# Add Cell column
colnames(df.umap) <- c("UMAP1","UMAP2")
df.umap$Cell = rownames(df.umap)
# Create data frame of tSNE compute by Seurat
df.FItsne <- data.frame(Embeddings(object = scObject$val, reduction = "FItSNE"))
# Add Cell column
df.FItsne$Cell = rownames(df.FItsne)

# Merge tSNE data frame to Cluster data frame
df.tsne <- merge(df.umap, df.FItsne, by = "Cell")
df.tsne <- merge(df.tsne, df.cluster, by = "Cell")

# Make df.tsne global 
tSNEmatrix$val <- df.tsne
mode$m <- 0
}

Dim1 <- paste(dimPkg$val,"1",sep="")
Dim2 <- paste(dimPkg$val,"2",sep="")

df.tSNEmatrix <- tSNEmatrix$val

df.tSNEmatrix$Celltype <- df.tSNEmatrix$Cell
df.tSNEmatrix$Celltype <- gsub("\\..*|_.*|-.*", "", df.tSNEmatrix$Celltype)

if("UMAP" %in% isolate(dimPkg$val)) {
  df.tSNEmatrix %>%
    dplyr::group_by(Cluster) %>%
    dplyr::summarize(x = median(x = UMAP1), y = median(x = UMAP2)) -> labCluster
} else {
  df.tSNEmatrix %>%
    dplyr::group_by(Cluster) %>%
    dplyr::summarize(x = median(x = FItSNE_1), y = median(x = FItSNE_2)) -> labCluster
}


ClustID <- df.tSNEmatrix[tail(seq_along(df.tSNEmatrix),2)] # Select last 2 columns
lables <- as.data.frame(table(ClustID))
lables <- lables[order(-lables$Freq), ]
ClustLab <- subset(lables, !duplicated(Cluster))
ClustInfo <- merge(labCluster, ClustLab, by = "Cluster")
names(ClustInfo) <- c("Cluster", Dim1, Dim2, "Celltype", "Freq")

if("useheader" %in% isolate(input$clustLabels)) {
	df.tSNEmatrix$Cluster <- df.tSNEmatrix$Celltype
	ClustInfo$Cluster <- ClustInfo$Celltype
}

p <- ggplot(data = df.tSNEmatrix, aes_string(Dim1, Dim2)) + 
			geom_point(aes(color = Cluster)) +
			#geom_point(data = labCluster, mapping = aes(x = labCluster$x, y = labCluster$y), colour="black", size = 0) +
            geom_text(data = ClustInfo, mapping = aes(label = Cluster), size = 5, colour="black") +
            theme(legend.title = element_blank()) 
