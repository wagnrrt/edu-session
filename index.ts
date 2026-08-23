import { Database } from "bun:sqlite";

const db = new Database("data/logins.sqlite")
db.query(`CREATE TABLE IF NOT EXISTS logins (
          id INTEGER PRIMARY KEY,
          email TEXT,
          notebook TEXT,
          received_in DATE
        )`).run()

type LoginPayload = {
  email: string;
  notebook: string;
}

type LoginRow = {
  id: number
  email: string
  notebook: string
  received_in: string
}


const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
const NOTEBOOK_REGEX = /^(NB|CB)-\d{2}$/

const server = Bun.serve({
  port: 3000,
  async fetch(req) {
    const url = new URL(req.url).pathname

    if (url === "/" && req.method === "GET") {
      return new Response(
        Bun.file("public/index.html"),
        { headers: { "Content-Type": "text/html; charset=utf-8" } })
    }

    if (url === "/app.js" && req.method === "GET")
      return new Response(Bun.file("public/app.js"), {
        headers: { "Content-Type": "text/javascript; charset=utf-8" }
      })

    if (url === "/style.css" && req.method === "GET")
      return new Response(Bun.file("public/style.css"), {
        headers: { "Content-Type": "text/css; charset=utf-8" }
      })

    if (url === "/logins" && req.method === "POST") {
      const data = (await req.json()) as LoginPayload
      if (!data.email || !data.notebook)
        return new Response(JSON.stringify({ success: false, error: "email and notebook are required fields" }), { status: 400 })

      if (typeof data.email !== "string")
        return new Response(JSON.stringify({ success: false, error: "email needs to be text" }), { status: 400 })
      if (typeof data.notebook !== "string")
        return new Response(JSON.stringify({ success: false, error: "notebook needs to be text" }), { status: 400 })

      data.email = data.email.trim()
      data.notebook = data.notebook.trim()

      if (!EMAIL_REGEX.test(data.email))
        return new Response(JSON.stringify({ success: false, error: "email invalid" }), { status: 400 })

      if (!NOTEBOOK_REGEX.test(data.notebook))
        return new Response(JSON.stringify({ success: false, error: "notebook invalid" }), { status: 400 })

      db.query("INSERT INTO logins (email, notebook, received_in) VALUES (?, ?, ?)").run(
        data.email, data.notebook, new Date().toISOString())
      return new Response(JSON.stringify({ success: true }), { status: 201 })
    }

    if (url === "/logins" && req.method === "GET") {
      const url = new URL(req.url)
      const conditions = []
      const values = []

      const email = url.searchParams.get("email")
      if (email) {
        conditions.push("email LIKE ?")
        values.push(`%${email}%`)
      }

      const notebook = url.searchParams.get("notebook")
      if (notebook) {
        conditions.push("notebook LIKE ?")
        values.push(`%${notebook}%`)
      }

      const cursor = url.searchParams.get("cursor")
      if (cursor) {
        conditions.push("received_in < ?")
        values.push(cursor)
      }

      const rawLimit = url.searchParams.get("limit")

      let limit = 50
      if (rawLimit !== null) {
        limit = Number(rawLimit)
        if (!Number.isInteger(limit) || limit < 1 || limit > 100)
          return new Response(JSON.stringify({ success: false, error: "limit invalid" }), { status: 400 })
      }

      values.push(limit + 1)

      let sql = "SELECT * FROM logins"
      if (conditions.length > 0)
        sql += " WHERE " + conditions.join(" AND ")

      sql += " ORDER BY received_in DESC LIMIT ?"

      const rows = db.query(sql).all(...values) as LoginRow[]
      const hasMore = rows.length > limit
      const page = rows.slice(0, limit)

      return new Response(JSON.stringify({
        success: true,
        logins: page,
        nextCursor: hasMore ? page[page.length - 1]?.received_in : null
      }), { status: 200 })
    }

    return new Response("Page not found", { status: 404 })
  },
});

console.log(`Listening on ${server.url}`);
