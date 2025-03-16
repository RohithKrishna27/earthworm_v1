-- Swigy Geni Logistics System Database Schema

-- Enable PostGIS extension for geographical data
CREATE EXTENSION IF NOT EXISTS postgis;

-- Delivery Partners Table
CREATE TABLE delivery_partners (
    partner_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE,
    vehicle_type VARCHAR(50) NOT NULL,
    license_plate VARCHAR(20),
    current_status VARCHAR(20) DEFAULT 'offline',
    rating DECIMAL(3,2) DEFAULT 0.00,
    join_date DATE NOT NULL,
    last_active TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    geolocation GEOGRAPHY(POINT), -- Current location
    available_for_delivery BOOLEAN DEFAULT FALSE,
    current_order_id INTEGER,
    device_token VARCHAR(255)
);

-- Restaurants Table
CREATE TABLE restaurants (
    restaurant_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    cuisine_type VARCHAR(50),
    rating DECIMAL(3,2) DEFAULT 0.00,
    open_time TIME,
    close_time TIME,
    is_active BOOLEAN DEFAULT TRUE,
    geolocation GEOGRAPHY(POINT), -- Restaurant location
    avg_preparation_time INTEGER, -- Average preparation time in minutes
    delivery_radius INTEGER, -- Delivery radius in meters
    onboarding_date DATE NOT NULL,
    commission_rate DECIMAL(5,2)
);

-- Customers Table
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE,
    join_date DATE NOT NULL,
    last_order_date TIMESTAMP WITH TIME ZONE,
    total_orders INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    default_address_id INTEGER,
    device_token VARCHAR(255)
);

-- Customer Addresses Table
CREATE TABLE customer_addresses (
    address_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    address_type VARCHAR(20) DEFAULT 'home',
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    zipcode VARCHAR(20) NOT NULL,
    landmark TEXT,
    geolocation GEOGRAPHY(POINT),
    is_default BOOLEAN DEFAULT FALSE
);

-- Orders Table
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    restaurant_id INTEGER REFERENCES restaurants(restaurant_id),
    partner_id INTEGER REFERENCES delivery_partners(partner_id),
    order_status VARCHAR(20) DEFAULT 'placed',
    placed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP WITH TIME ZONE,
    prepared_at TIMESTAMP WITH TIME ZONE,
    picked_up_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    estimated_delivery_time TIMESTAMP WITH TIME ZONE,
    delivery_address_id INTEGER REFERENCES customer_addresses(address_id),
    payment_method VARCHAR(20),
    payment_status VARCHAR(20) DEFAULT 'pending',
    subtotal DECIMAL(10,2) NOT NULL,
    delivery_fee DECIMAL(10,2) NOT NULL,
    taxes DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    special_instructions TEXT,
    delivery_rating INTEGER,
    restaurant_rating INTEGER,
    order_type VARCHAR(20) DEFAULT 'delivery'
);

-- Order Items Table
CREATE TABLE order_items (
    item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id),
    menu_item_name VARCHAR(100) NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    special_instructions TEXT,
    item_status VARCHAR(20) DEFAULT 'placed'
);

-- Delivery Zones Table
CREATE TABLE delivery_zones (
    zone_id SERIAL PRIMARY KEY,
    zone_name VARCHAR(100) NOT NULL,
    zone_boundary GEOGRAPHY(POLYGON) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    base_delivery_fee DECIMAL(10,2),
    min_delivery_time INTEGER, -- Minimum delivery time in minutes
    max_delivery_time INTEGER, -- Maximum delivery time in minutes
    partner_bonus_rate DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Delivery Batch Table (for grouping multiple orders)
CREATE TABLE delivery_batches (
    batch_id SERIAL PRIMARY KEY,
    partner_id INTEGER REFERENCES delivery_partners(partner_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'active',
    estimated_completion_time TIMESTAMP WITH TIME ZONE,
    total_distance DECIMAL(10,2), -- in kilometers
    optimization_score DECIMAL(5,2) -- efficiency score
);

-- Batch Orders Table (linking batches to orders)
CREATE TABLE batch_orders (
    batch_id INTEGER REFERENCES delivery_batches(batch_id),
    order_id INTEGER REFERENCES orders(order_id),
    sequence_number INTEGER NOT NULL,
    estimated_pickup_time TIMESTAMP WITH TIME ZONE,
    estimated_delivery_time TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (batch_id, order_id)
);

-- Partner Location History Table
CREATE TABLE partner_location_history (
    history_id SERIAL PRIMARY KEY,
    partner_id INTEGER REFERENCES delivery_partners(partner_id),
    geolocation GEOGRAPHY(POINT) NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    speed DECIMAL(5,2), -- in km/h
    bearing INTEGER, -- direction in degrees
    battery_level INTEGER -- device battery percentage
);

-- Order Tracking Table
CREATE TABLE order_tracking (
    tracking_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id),
    status_change VARCHAR(50) NOT NULL,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    location GEOGRAPHY(POINT),
    notes TEXT
);

-- Demand Forecasting Table
CREATE TABLE demand_forecasts (
    forecast_id SERIAL PRIMARY KEY,
    zone_id INTEGER REFERENCES delivery_zones(zone_id),
    forecast_date DATE NOT NULL,
    hour_of_day INTEGER CHECK (hour_of_day >= 0 AND hour_of_day < 24),
    predicted_orders INTEGER NOT NULL,
    predicted_partners_needed INTEGER NOT NULL,
    confidence_score DECIMAL(5,2),
    weather_condition VARCHAR(50),
    is_holiday BOOLEAN DEFAULT FALSE,
    special_event TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Partner Incentives Table
CREATE TABLE partner_incentives (
    incentive_id SERIAL PRIMARY KEY,
    zone_id INTEGER REFERENCES delivery_zones(zone_id),
    incentive_name VARCHAR(100) NOT NULL,
    description TEXT,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    min_deliveries INTEGER,
    bonus_amount DECIMAL(10,2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_by VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Partner Performance Table
CREATE TABLE partner_performance (
    performance_id SERIAL PRIMARY KEY,
    partner_id INTEGER REFERENCES delivery_partners(partner_id),
    date DATE NOT NULL,
    total_deliveries INTEGER DEFAULT 0,
    on_time_deliveries INTEGER DEFAULT 0,
    average_delivery_time INTEGER, -- in minutes
    total_distance DECIMAL(10,2), -- in kilometers
    total_earnings DECIMAL(10,2),
    total_online_hours DECIMAL(5,2),
    acceptance_rate DECIMAL(5,2),
    cancellation_rate DECIMAL(5,2),
    customer_rating DECIMAL(3,2),
    UNIQUE (partner_id, date)
);

-- Route Optimization Settings Table
CREATE TABLE route_optimization_settings (
    setting_id SERIAL PRIMARY KEY,
    zone_id INTEGER REFERENCES delivery_zones(zone_id),
    max_batch_size INTEGER DEFAULT 3,
    max_wait_time INTEGER, -- in minutes
    max_detour_distance DECIMAL(5,2), -- in kilometers
    traffic_factor DECIMAL(3,2) DEFAULT 1.0,
    weather_factor DECIMAL(3,2) DEFAULT 1.0,
    time_window_optimization BOOLEAN DEFAULT TRUE,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by VARCHAR(100)
);

-- Traffic Patterns Table
CREATE TABLE traffic_patterns (
    pattern_id SERIAL PRIMARY KEY,
    zone_id INTEGER REFERENCES delivery_zones(zone_id),
    day_of_week INTEGER CHECK (day_of_week >= 0 AND day_of_week <= 6),
    hour_of_day INTEGER CHECK (hour_of_day >= 0 AND hour_of_day < 24),
    congestion_level DECIMAL(3,2), -- 0 to 1 scale
    average_speed DECIMAL(5,2), -- in km/h
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_delivery_partners_geolocation ON delivery_partners USING GIST(geolocation);
CREATE INDEX idx_restaurants_geolocation ON restaurants USING GIST(geolocation);
CREATE INDEX idx_customer_addresses_geolocation ON customer_addresses USING GIST(geolocation);
CREATE INDEX idx_delivery_zones_boundary ON delivery_zones USING GIST(zone_boundary);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_placed_at ON orders(placed_at);
CREATE INDEX idx_partner_location_history_partner_id ON partner_location_history(partner_id);
CREATE INDEX idx_partner_location_history_recorded_at ON partner_location_history(recorded_at);
CREATE INDEX idx_order_tracking_order_id ON order_tracking(order_id);
CREATE INDEX idx_demand_forecasts_zone_date_hour ON demand_forecasts(zone_id, forecast_date, hour_of_day);
CREATE INDEX idx_partner_performance_partner_date ON partner_performance(partner_id, date);
CREATE INDEX idx_traffic_patterns_zone_day_hour ON traffic_patterns(zone_id, day_of_week, hour_of_day);

-- Create view for partner availability
CREATE VIEW available_partners AS
SELECT 
    dp.partner_id,
    dp.name,
    dp.vehicle_type,
    dp.rating,
    dp.geolocation,
    dp.current_status,
    pp.average_delivery_time,
    pp.on_time_deliveries::float / NULLIF(pp.total_deliveries, 0) as on_time_rate
FROM 
    delivery_partners dp
LEFT JOIN 
    partner_performance pp ON dp.partner_id = pp.partner_id AND pp.date = CURRENT_DATE
WHERE 
    dp.current_status = 'online' 
    AND dp.available_for_delivery = TRUE
    AND dp.current_order_id IS NULL;

-- Create view for order delivery metrics
CREATE VIEW order_delivery_metrics AS
SELECT 
    o.order_id,
    o.restaurant_id,
    o.customer_id,
    o.partner_id,
    r.name as restaurant_name,
    c.name as customer_name,
    dp.name as partner_name,
    o.placed_at,
    o.delivered_at,
    EXTRACT(EPOCH FROM (o.delivered_at - o.placed_at))/60 as total_delivery_time,
    EXTRACT(EPOCH FROM (o.accepted_at - o.placed_at))/60 as acceptance_time,
    EXTRACT(EPOCH FROM (o.prepared_at - o.accepted_at))/60 as preparation_time,
    EXTRACT(EPOCH FROM (o.picked_up_at - o.prepared_at))/60 as pickup_waiting_time,
    EXTRACT(EPOCH FROM (o.delivered_at - o.picked_up_at))/60 as transit_time,
    CASE WHEN o.delivered_at <= o.estimated_delivery_time THEN TRUE ELSE FALSE END as is_on_time,
    o.delivery_rating,
    o.restaurant_rating,
    o.total_amount
FROM 
    orders o
JOIN 
    restaurants r ON o.restaurant_id = r.restaurant_id
JOIN 
    customers c ON o.customer_id = c.customer_id
LEFT JOIN 
    delivery_partners dp ON o.partner_id = dp.partner_id
WHERE 
    o.order_status = 'delivered';