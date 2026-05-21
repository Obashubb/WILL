# WILL — Product Requirements Document

**AI-Based Wearable Monitoring System for Sickle Cell Patients**

> This document has two parts:
> 1. **[Current PRD](#current-prd-with-cloud-backend)** — with cloud backend.
> 2. **[Appendix A](#appendix-a-original-prd-without-cloud-backend)** — original PRD without cloud backend, kept for reference.

---

## Table of contents

1. [Project overview](#1-project-overview)
2. [Aim](#2-aim)
3. [Objectives](#3-objectives)
4. [Scope](#4-scope)
   - [4.1 Hardware](#41-hardware)
   - [4.2 Mobile application](#42-mobile-application)
   - [4.3 Cloud backend](#43-cloud-backend)
   - [4.4 Artificial intelligence](#44-artificial-intelligence)
5. [Functional requirements](#5-functional-requirements)
   - [5.1 Wearable device](#51-wearable-device)
   - [5.2 Mobile application](#52-mobile-application)
   - [5.3 Cloud backend](#53-cloud-backend)
6. [Non-functional requirements](#6-non-functional-requirements)
7. [Backend requirements](#7-backend-requirements)
8. [Machine learning requirements](#8-machine-learning-requirements)
9. [System architecture](#9-system-architecture)
10. [Expected capabilities](#10-expected-capabilities)
11. [Limitations](#11-limitations)
12. [Future improvements](#12-future-improvements)
13. [Appendix A — Original PRD (no cloud backend)](#appendix-a-original-prd-without-cloud-backend)

---

## Current PRD (with cloud backend)

### 1. Project overview

WILL is an intelligent wearable monitoring system for sickle cell patients. The system has three pieces:

- a **wearable wristband** that collects physiological data,
- a **mobile application** that visualizes data and surfaces AI insights, and
- a **cloud backend** that handles secure storage, sync, auth, and data management.

The wearable measures:

- Heart rate
- Blood oxygen saturation (SpO₂)
- Body temperature
- Physical activity and movement

Readings are transmitted to the mobile app over **Bluetooth Low Energy (BLE)**. The app displays real-time health information, stores history, and exposes ML-generated insights. The cloud layer adds storage, sync, authentication, and supports predictive analysis. The product also covers **hydration tracking** and **medication reminders**.

### 2. Aim

Design and develop an AI-powered wearable monitoring system that continuously monitors the physiological condition of sickle cell patients and provides intelligent health insights through a mobile application and cloud backend.

### 3. Objectives

1. Design a wearable wristband that collects physiological data from sickle cell patients.
2. Develop a mobile application for real-time health monitoring and visualization.
3. Establish wireless BLE communication between the wearable and the app.
4. Implement machine learning for predictive health analysis.
5. Build a cloud backend for storage and synchronization.
6. Provide hydration tracking and medication reminders.
7. Improve proactive monitoring and management of sickle cell patients.

### 4. Scope

The scope covers hardware, software, machine learning, and cloud backend systems.

#### 4.1 Hardware

Wearable wristband prototype built around:

| Component | Role |
|---|---|
| ESP32-C3 SuperMini | Microcontroller |
| MAX30102 | Pulse oximeter (HR + SpO₂) |
| DS18B20 | Temperature sensor |
| LIS3DH | Accelerometer (activity / movement) |
| Li-Po battery | Power |
| TP4056 | Charging module |
| Coin vibration motor | Haptic alerts |

The hardware collects physiological data and transmits it wirelessly to the mobile application.

#### 4.2 Mobile application

Built in **Flutter** for Android and iOS. The app will:

- connect to the wearable over BLE
- display real-time physiological readings
- store and display historical records
- provide AI-generated health insights
- track hydration intake
- manage medication schedules and reminders
- display alerts and notifications
- synchronize data with the cloud backend

#### 4.3 Cloud backend

Centralized data management and sync. The backend will:

- store patient health records
- synchronize sensor readings
- manage user authentication
- store medication and reminder schedules
- support machine learning integration
- maintain historical health data

Likely implemented with **Firebase Authentication** and **Cloud Firestore**.

#### 4.4 Artificial intelligence

The ML system analyzes physiological sensor data and generates predictive health insights:

- analyze health patterns
- infer stress levels
- infer hydration levels
- detect abnormal conditions
- generate intelligent recommendations

A **Random Forest** classifier will be used for predictive analysis.

### 5. Functional requirements

#### 5.1 Wearable device

The wearable shall:

- measure heart rate
- measure blood oxygen saturation (SpO₂)
- measure body temperature
- detect patient activity and movement
- transmit sensor readings to the mobile application
- provide vibration alerts for abnormal conditions
- operate on rechargeable battery power

#### 5.2 Mobile application

The mobile application is organized into five modules.

**Dashboard**
- display real-time sensor readings
- display device connection status
- display overall health summary
- show current physiological conditions

**History**
- store historical sensor readings
- display past health trends
- allow users to review previous records

**Insights**
- display AI-generated health analysis
- display stress level predictions
- display hydration level predictions
- provide intelligent recommendations
- display overall health condition

**Care**
- track water intake
- monitor hydration goals
- manage medication schedules and reminders
- display reminder notifications

**Profile**
- display patient information
- manage device settings
- manage application settings
- support account management

#### 5.3 Cloud backend

The backend shall:

- store physiological sensor data
- synchronize data across sessions
- manage user accounts and authentication
- process health records
- support AI-based predictions
- manage reminders and notifications
- maintain secure patient records

### 6. Non-functional requirements

The system should:

- provide real-time monitoring
- maintain low power consumption
- provide stable BLE communication
- be lightweight and portable
- provide a user-friendly interface
- support secure cloud storage
- provide reliable data synchronization
- maintain acceptable response time

### 7. Backend requirements

The backend provides cloud services for storage, sync, authentication, and predictive analysis. It shall:

- store sensor readings in a cloud database
- manage user authentication and profiles
- synchronize health data between wearable, mobile, and cloud
- support ML prediction workflows
- manage hydration and medication reminders
- maintain historical health records
- support secure access to patient data

Likely Firebase services:

- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging

### 8. Machine learning requirements

The ML system shall:

- use physiological sensor data as input
- analyze patterns in patient readings
- classify health conditions
- generate predictive insights
- detect abnormal trends

Algorithm: **Random Forest**.

Possible outputs:

- Normal condition
- Elevated stress level
- Possible dehydration
- Abnormal oxygen saturation
- Health risk alerts

### 9. System architecture

The system has four layers:

| Layer | Responsibility |
|---|---|
| **9.1 Wearable hardware** | Collect physiological data via on-wrist sensors |
| **9.2 Communication** | BLE link between wearable and mobile app |
| **9.3 Application** | Display health data, manage reminders, surface AI insights |
| **9.4 Cloud backend + AI** | Cloud storage, sync, auth, ML analysis |

### 10. Expected capabilities

The completed system should be capable of:

- monitoring sickle cell patients in real time
- collecting physiological sensor data
- transmitting data wirelessly
- storing records in the cloud
- generating intelligent health insights
- predicting stress and hydration levels
- detecting abnormal physiological conditions
- supporting hydration and medication management
- providing health alerts and reminders
- improving patient awareness and preventive healthcare

### 11. Limitations

- Prototype accuracy may not match medical-grade systems.
- ML predictions depend on dataset quality.
- Battery life may be limited.
- BLE communication range is limited.
- Cloud functionality depends on internet availability.

### 12. Future improvements

- Integration with hospitals and healthcare providers
- Caregiver and doctor monitoring dashboard
- GPS emergency location tracking
- Smartwatch-sized custom PCB
- Cloud-based advanced AI analytics
- Push notification services
- Support for additional health sensors
- Integration with smartwatches and wearable ecosystems

---

## Appendix A — Original PRD (without cloud backend)

> Earlier scope, kept for reference. The current PRD above supersedes it by adding the cloud backend layer.

### A.1 Project overview

A wearable wristband and mobile application for real-time health monitoring of sickle cell patients. The wearable collects:

- Heart rate
- Blood oxygen saturation (SpO₂)
- Body temperature
- Activity / movement

Data is transmitted to the mobile app over BLE. The app displays the patient's health information and uses ML for insights such as stress and hydration analysis. The product also includes medication reminders and water intake tracking.

### A.2 Aim

Develop an intelligent wearable monitoring system capable of tracking vital signs in sickle cell patients and providing predictive insights through a mobile application.

### A.3 Objectives

1. Design a wearable wristband that collects physiological data.
2. Develop a mobile application for real-time health monitoring.
3. Establish BLE communication between wearable and app.
4. Implement ML for predictive health analysis.
5. Provide hydration and medication reminder features.
6. Improve monitoring and management of sickle cell patients.

### A.4 Scope

**Hardware**
- ESP32-C3 microcontroller
- MAX30102 pulse oximeter
- DS18B20 temperature sensor
- LIS3DH accelerometer
- Li-Po battery + charging module
- Vibration motor for alerts

**Mobile application**
- Connect to the wearable over BLE
- Display real-time health data
- Show historical readings
- Display AI-generated insights
- Track hydration intake
- Manage medication reminders
- Notify users of abnormal conditions

**AI**
- Analyze physiological data
- Detect abnormal trends
- Predict stress levels
- Infer hydration status
- Generate recommendations

### A.5 Functional requirements

**Wearable device**
- Measure heart rate, SpO₂, body temperature
- Detect movement / activity
- Send sensor data to the mobile application
- Vibration alerts on abnormal conditions
- Rechargeable battery power

**Mobile application**

*Dashboard* — real-time sensor readings, device connection status, overall health summary.

*History* — store and display previous readings, historical trends.

*Insights* — AI-generated health analysis, stress and hydration predictions, recommendations.

*Care section* — water intake, medication intake, reminders.

*Profile* — patient info, device management, app settings.

### A.6 Non-functional requirements

- Low power consumption
- Real-time monitoring
- User-friendly
- Stable Bluetooth communication
- Lightweight and portable
- Responsive mobile interface

### A.7 Backend requirements

- Receive sensor data from the wearable
- Process physiological data
- Manage user information
- Run ML predictions
- Store historical readings
- Manage reminders and notifications

### A.8 Machine learning requirements

- Use physiological sensor data as input
- Perform classification and prediction
- Detect patterns in health readings
- Generate predictive insights

Possible outputs: normal condition, elevated stress, possible dehydration, abnormal oxygen level.

### A.9 System architecture

| Layer | Responsibility |
|---|---|
| Wearable hardware | Collect physiological data |
| Communication | BLE between device and mobile app |
| Application + AI | Process data, display readings, predictive analysis |

### A.10 Expected capabilities

- Monitor sickle cell patients in real time
- Provide intelligent health insights
- Detect abnormal physiological conditions
- Support hydration and medication management
- Improve patient awareness and preventive care

### A.11 Limitations

- Prototype accuracy may not match medical-grade devices
- AI predictions depend on dataset quality
- Battery life may be limited
- Internet / cloud integration may not be fully implemented

### A.12 Future improvements

- Cloud database integration
- Doctor / caregiver dashboard
- GPS emergency tracking
- Advanced AI prediction models
- Smartwatch-sized custom PCB
- Push notifications via internet
