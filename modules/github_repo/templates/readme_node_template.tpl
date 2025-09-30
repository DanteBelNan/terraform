# 🚀 ${app_name}

This is a robust and pre-configured template designed to quickly launch a **complete backend and frontend microservice**, utilizing **Node.js** on the server and **Vue** on the client, all orchestrated with **Docker** and backed by a **PostgreSQL** database.

---

## 📦 Project Structure

The project is structured to offer a ready-to-use development and production environment, clearly separating the backend, frontend, and infrastructure:

| Component | Primary Technology | Exposed Port | Purpose |
| :--- | :--- | :--- | :--- |
| **Backend** | **Node.js** | Internal (Accessed via Nginx) | API server and business logic management (HTTP/S and Sockets). |
| **Frontend** | **Vue.js** | N/A | Interactive user interface and web client. |
| **Database** | **PostgreSQL** | `5432` | Persistent and relational data storage. |
| **Proxy / Web Server** | **Nginx** | `80` (Main) | Gateway, serves the frontend, and acts as a reverse proxy for the backend. |

---

## ✨ Key Features

* **Versatile Node.js Backend:** The backend server is capable of handling:
    * **HTTP/S Requests (RESTful):** For traditional data communication.
    * **Socket Communication:** For **real-time** functionalities (chat, live notifications, etc.).
* **Docker Containerization:** All services (Node.js, Vue, Nginx, PostgreSQL) run inside **Docker containers**, ensuring a **consistent** and **isolated** execution environment on any machine.
* **Unified Access (Nginx):** An **Nginx** container acts as the main entry point:
    * **Port 80:** Exposed to receive all incoming requests.
    * It serves the **Frontend (Vue)** and acts as a **reverse proxy** for requests directed to the **Backend (Node.js)**.
* **Modern Frontend (Vue):** A modern user interface built with **Vue.js** for a fast and reactive user experience.
* **Persistent Database:** Includes a ready-to-use **PostgreSQL** container on the default port `5432`, the most advanced relational database.

---

## 🛠️ Requirements

Make sure you have the following installed:

* **Docker**
* **Docker Compose**

---

## ⚙️ Usage and Installation

1.  **Clone the Repository:**
    ```bash
    git clone [https://github.com/$](https://github.com/$){github_owner}/${app_name}.git
    cd ${app_name}
    ```

2.  **Environment Variables Configuration:**
    * Create a **`.env`** file in the project root to define critical variables like PostgreSQL database credentials (e.g., `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`).

3.  **Build and Run Containers:**
    Use `docker-compose` to build the images and run all services in detached mode. This command ensures everything is built correctly the first time.

    ```bash
    docker-compose up -d --build
    ```

4.  **Application Access:**
    * **Web Application (Frontend):** Access your browser at **`http://localhost`**. Nginx will serve the Vue application.
    * **Database (PostgreSQL):** The database connection is accessible on host port **`5432`**.

---

## 🛑 Stop and Clean Up

To stop and remove the containers and the created networks:

```bash
docker-compose down