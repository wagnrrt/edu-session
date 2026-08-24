let cursor = null
let filtro = {}
let limite = 20

const corpoTabela = document.querySelector("#corpo-tabela")
const btnCarregarMais = document.querySelector("#btn-carregar-mais")
const msgVazio = document.querySelector("#msg-vazio")
const contador = document.querySelector("#contador")
const inputNotebook = document.querySelector("#input-notebook")
const inputEmail = document.querySelector("#input-email")
const selectLimit = document.querySelector("#select-limit")

function formatarData(iso) {
  return new Intl.DateTimeFormat("pt-BR", {
    dateStyle: "short",
    timeStyle: "short",
  }).format(new Date(iso))
}

function criarCelula(texto) {
  const td = document.createElement("td")
  td.textContent = texto
  return td
}

function adicionarLinha(login) {
  const tr = document.createElement("tr")
  tr.appendChild(criarCelula(login.notebook))
  tr.appendChild(criarCelula(login.name ?? "-"))
  tr.appendChild(criarCelula(login.email))
  tr.appendChild(criarCelula(formatarData(login.received_in)))
  corpoTabela.appendChild(tr)
}

function atualizarContador() {
  const total = corpoTabela.children.length
  contador.textContent =
    `${total} registro${total === 1 ? "" : "s"}` + (cursor ? " (tem mais)" : "")
}

async function carregar(novaPagina = false) {
  if (!novaPagina) {
    cursor = null
    corpoTabela.innerHTML = ""
  }

  const params = new URLSearchParams({ limit: String(limite) })
  if (cursor) params.set("cursor", cursor)
  if (filtro.notebook) params.set("notebook", filtro.notebook)
  if (filtro.email) params.set("email", filtro.email)

  try {
    const resposta = await fetch(`/logins?${params}`)
    if (!resposta.ok) throw new Error(resposta.status)

    const dados = await resposta.json()

    for (const login of dados.logins) {
      adicionarLinha(login)
    }

    cursor = dados.nextCursor
    btnCarregarMais.classList.toggle("visivel", cursor !== null)
    msgVazio.hidden = corpoTabela.children.length > 0
    atualizarContador()
  } catch {
    contador.textContent = "erro ao buscar logins"
  }
}

document.querySelector("#form-busca").addEventListener("submit", (evento) => {
  evento.preventDefault()
  filtro = {
    notebook: inputNotebook.value.trim(),
    email: inputEmail.value.trim(),
  }
  carregar(false)
})

selectLimit.addEventListener("change", () => {
  limite = Number(selectLimit.value)
  carregar(false)
})

document.querySelector("#btn-limpar").addEventListener("click", () => {
  inputNotebook.value = ""
  inputEmail.value = ""
  selectLimit.value = "20"
  limite = 20
  filtro = {}
  carregar(false)
})

btnCarregarMais.addEventListener("click", () => carregar(true))

carregar()
