# Graph Report - nlp-project  (2026-06-20)

## Corpus Check
- 23 files · ~66,998 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 99 nodes · 231 edges · 8 communities detected
- Extraction: 42% EXTRACTED · 58% INFERRED · 0% AMBIGUOUS · INFERRED: 135 edges (avg confidence: 0.64)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]

## God Nodes (most connected - your core abstractions)
1. `CustomException` - 29 edges
2. `TrainPipeline` - 24 edges
3. `GCloudSync` - 19 edges
4. `DataTransformation` - 16 edges
5. `ModelEvaluation` - 12 edges
6. `ModelTrainer` - 11 edges
7. `DataIngestion` - 10 edges
8. `DataTransformationArtifacts` - 10 edges
9. `PredictionPipeline` - 10 edges
10. `ModelTrainerArtifacts` - 9 edges

## Surprising Connections (you probably didn't know these)
- `training()` --calls--> `TrainPipeline`  [INFERRED]
  app.py → hate\pipeline\train_pipeline.py
- `predict_route()` --calls--> `PredictionPipeline`  [INFERRED]
  app.py → hate\pipeline\prediction_pipeline.py
- `predict_route()` --calls--> `CustomException`  [INFERRED]
  app.py → hate\exception\__init__.py
- `DataIngestion` --uses--> `GCloudSync`  [INFERRED]
  hate\components\data_ingestion.py → hate\configuration\gcloud_syncer.py
- `DataIngestion` --uses--> `DataIngestionConfig`  [INFERRED]
  hate\components\data_ingestion.py → hate\entity\config_entity.py

## Communities

### Community 0 - "Community 0"
Cohesion: 0.3
Nodes (8): DataTransformationArtifacts, ModelEvaluationArtifacts, ModelTrainerArtifacts, ModelEvaluation, Method Name :   initiate_model_evaluation             Description :   This func, :param model_evaluation_config: Configuration for model eva            model = m, :return: Fetch best model from gcloud storage and store inside best model direct, :param model: Currently trained model or best model from gcloud storage

### Community 1 - "Community 1"
Cohesion: 0.25
Nodes (4): DataTransformation, CustomException, error_message_detail(), :param error_message: error message in string format

### Community 2 - "Community 2"
Cohesion: 0.24
Nodes (6): DataIngestionConfig, DataTransformationConfig, ModelEvaluationConfig, ModelPusherConfig, ModelTrainerConfig, TrainPipeline

### Community 3 - "Community 3"
Cohesion: 0.26
Nodes (5): ModelPusherArtifacts, GCloudSync, ModelPusher, :param model_pusher_config: Configuration for model pusher, Method Name :   initiate_model_pusher             Description :   This method i

### Community 4 - "Community 4"
Cohesion: 0.27
Nodes (2): ModelArchitecture, ModelTrainer

### Community 5 - "Community 5"
Cohesion: 0.43
Nodes (4): DataIngestionArtifacts, PredictionPipeline, Method Name :   get_model_from_gcloud         Description :   This method to ge, load image, returns cuda tensor

### Community 6 - "Community 6"
Cohesion: 0.43
Nodes (1): DataIngestion

### Community 7 - "Community 7"
Cohesion: 0.4
Nodes (3): predict_route(), training(), Exception

## Knowledge Gaps
- **1 isolated node(s):** `:param error_message: error message in string format`
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 4`** (11 nodes): `model_trainer.py`, `model.py`, `ModelArchitecture`, `.get_model()`, `.__init__()`, `ModelTrainer`, `.__init__()`, `.initiate_model_trainer()`, `.spliting_data()`, `.tokenizing()`, `.start_model_trainer()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 6`** (7 nodes): `DataIngestion`, `.get_data_from_gcloud()`, `.initiate_data_ingestion()`, `.unzip_and_clean()`, `.sync_folder_from_gcloud()`, `data_ingestion.py`, `.start_data_ingestion()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `TrainPipeline` connect `Community 2` to `Community 0`, `Community 1`, `Community 3`, `Community 4`, `Community 5`, `Community 6`, `Community 7`?**
  _High betweenness centrality (0.235) - this node is a cross-community bridge._
- **Why does `CustomException` connect `Community 1` to `Community 0`, `Community 3`, `Community 4`, `Community 5`, `Community 6`, `Community 7`?**
  _High betweenness centrality (0.232) - this node is a cross-community bridge._
- **Why does `GCloudSync` connect `Community 3` to `Community 0`, `Community 5`, `Community 6`?**
  _High betweenness centrality (0.107) - this node is a cross-community bridge._
- **Are the 25 inferred relationships involving `CustomException` (e.g. with `predict_route()` and `.get_data_from_gcloud()`) actually correct?**
  _`CustomException` has 25 INFERRED edges - model-reasoned connections that need verification._
- **Are the 16 inferred relationships involving `TrainPipeline` (e.g. with `DataIngestion` and `DataTransformation`) actually correct?**
  _`TrainPipeline` has 16 INFERRED edges - model-reasoned connections that need verification._
- **Are the 16 inferred relationships involving `GCloudSync` (e.g. with `DataIngestion` and `ModelEvaluation`) actually correct?**
  _`GCloudSync` has 16 INFERRED edges - model-reasoned connections that need verification._
- **Are the 9 inferred relationships involving `DataTransformation` (e.g. with `DataTransformationConfig` and `DataIngestionArtifacts`) actually correct?**
  _`DataTransformation` has 9 INFERRED edges - model-reasoned connections that need verification._