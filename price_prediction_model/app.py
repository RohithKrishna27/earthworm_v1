from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import Optional
import pandas as pd
import joblib
import uvicorn
import os

# Initialize FastAPI app
app = FastAPI(
    title="Agricultural Price Prediction API",
    description="API for predicting agricultural commodity prices based on various factors",
    version="1.0.0"
)

# Define the input data model
class PredictionInput(BaseModel):
    state: str
    district: str
    market: str
    commodity: str
    variety: str
    modal_price: float
    temperature_c: float
    humidity: float
    wind_kph: float
    Weekday: str
    
    class Config:
        schema_extra = {
            "example": {
                "state": "Karnataka",
                "district": "Bangalore",
                "market": "Binny Mill (F&V), Bangalore",
                "commodity": "Apple",
                "variety": "Apple",
                "modal_price": 13000,
                "temperature_c": 32.3,
                "humidity": 24,
                "wind_kph": 20.56,
                "Weekday": "Monday"
            }
        }

# Define the output data model
class PredictionOutput(BaseModel):
    predicted_price: float = Field(..., description="Predicted average price")
    
# Function to load the model and column information
def load_model_and_info():
    model_path = "agricultural_price_model.pkl"
    column_info_path = "column_info.pkl"
    
    if not os.path.exists(model_path) or not os.path.exists(column_info_path):
        raise FileNotFoundError("Model files not found. Please train the model first.")
    
    model = joblib.load(model_path)
    column_info = joblib.load(column_info_path)
    
    return model, column_info

# Prediction function
def predict_price(model, column_info, input_data):
    # Convert input data to DataFrame
    df = pd.DataFrame([input_data.dict()])
    
    # Ensure all expected columns are present
    expected_cols = column_info['all_cols']
    
    # Add missing columns with default values
    for col in expected_cols:
        if col not in df.columns:
            if col in column_info['numerical_cols']:
                df[col] = 0  # Default numerical value
            else:
                df[col] = 'unknown'  # Default categorical value
    
    # Remove extra columns
    extra_cols = [col for col in df.columns if col not in expected_cols]
    if extra_cols:
        print(f"Removing extra columns not used during training: {extra_cols}")
        df = df.drop(columns=extra_cols)
    
    # Ensure columns are in the same order as during training
    df = df[expected_cols]
    
    # Make prediction
    prediction = model.predict(df)
    return prediction[0]

# Define root endpoint
@app.get("/")
async def root():
    return {"message": "Welcome to the Agricultural Price Prediction API"}

# Define health check endpoint
@app.get("/health")
async def health_check():
    try:
        # Attempt to load the model to verify it's available
        load_model_and_info()
        return {"status": "healthy", "message": "API is operational"}
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"API is not healthy: {str(e)}")

# Define prediction endpoint
@app.post("/predict", response_model=PredictionOutput)
async def make_prediction(input_data: PredictionInput):
    try:
        model, column_info = load_model_and_info()
        prediction = predict_price(model, column_info, input_data)
        return {"predicted_price": float(prediction)}
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")

# Define model info endpoint
@app.get("/model-info")
async def get_model_info():
    try:
        _, column_info = load_model_and_info()
        return {
            "categorical_features": column_info['categorical_cols'],
            "numerical_features": column_info['numerical_cols'],
            "total_features": len(column_info['all_cols'])
        }
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving model info: {str(e)}")

# Run the API with Uvicorn if this script is executed directly
if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)