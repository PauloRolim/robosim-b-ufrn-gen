package circus.robocalc.robosim.generator.cssp;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;

import org.eclipse.emf.common.util.TreeIterator;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.util.EcoreUtil;
import org.eclipse.xtext.diagnostics.Severity;
import org.eclipse.xtext.generator.GeneratorContext;
import org.eclipse.xtext.generator.JavaIoFileSystemAccess;
import org.eclipse.xtext.resource.XtextResourceSet;
import org.eclipse.xtext.util.CancelIndicator;
import org.eclipse.xtext.validation.CheckMode;
import org.eclipse.xtext.validation.IResourceValidator;
import org.eclipse.xtext.validation.Issue;

import com.google.inject.Injector;

import circus.robocalc.robosim.SimMachineDef;
import circus.robocalc.robosim.generator.cssp.sim.SimGenerator;
import circus.robocalc.robosim.textual.RoboSimStandaloneSetup;

public class TraductorService {

    private static final String[] ROBOCHART_LIBS = {
        "lib/robochart/core.rct",
        "lib/robochart/set_toolkit.rct",
        "lib/robochart/sequence_toolkit.rct",
        "lib/robochart/function_toolkit.rct",
        "lib/robochart/relation_toolkit.rct"
    };

    private static final String[] ROBOSIM_LIBS = {
        "lib/robosim/score.rst"
    };

    // Injector cacheado: inicialização Xtext ocorre só uma vez por instância
    private Injector injector;

    public static class Resultado {
        public final boolean sucesso;
        public final List<String> mensagens;
        public final File pastaSaida;

        public Resultado(boolean sucesso, List<String> mensagens, File pastaSaida) {
            this.sucesso = sucesso;
            this.mensagens = mensagens;
            this.pastaSaida = pastaSaida;
        }
    }

    private Injector getInjector() {
        if (injector == null) {
            injector = new RoboSimStandaloneSetup()
                    .createInjectorAndDoEMFRegistration();
        }
        return injector;
    }

    // =========================================================
    // listarMaquinas
    // =========================================================
    public List<String> listarMaquinas(File inputFile, Consumer<String> log) {
        Consumer<String> registrar = msg -> {
            if (log != null) log.accept(msg);
        };
        try {
            registrar.accept("→ Analisando modelo para listar máquinas...");
            Resource resource = prepararResource(inputFile, registrar);

            List<String> nomes = new ArrayList<>();
            TreeIterator<EObject> it = resource.getAllContents();
            while (it.hasNext()) {
                EObject obj = it.next();
                if (obj instanceof SimMachineDef) {
                    String nome = ((SimMachineDef) obj).getName();
                    if (nome != null && !nomes.contains(nome)) {
                        nomes.add(nome);
                    }
                }
            }
            registrar.accept("→ " + nomes.size() + " máquina(s) encontrada(s): " + nomes);
            return nomes;
        } catch (Exception e) {
            registrar.accept("\n❌ Erro ao listar máquinas: " + e.getMessage());
            return new ArrayList<>();
        }
    }

    // =========================================================
    // traduzir — sobrecargas para compatibilidade
    // =========================================================

    /** Traduz todas as máquinas (compatibilidade com Main.java). */
    public Resultado traduzir(File inputFile, File outputDir, Consumer<String> log) {
        return traduzir(inputFile, outputDir, (List<String>) null, log);
    }

    /** Traduz uma única máquina (compatibilidade com versão anterior). */
    public Resultado traduzir(File inputFile, File outputDir,
                              String maquinaSelecionada, Consumer<String> log) {
        List<String> lista = (maquinaSelecionada != null)
                ? List.of(maquinaSelecionada) : null;
        return traduzir(inputFile, outputDir, lista, log);
    }

    /**
     * Traduz o arquivo .rst para CSSP.
     * Parse e validação ocorrem UMA vez; geração ocorre uma vez por máquina.
     * @param maquinas null ou vazia = todas; lista com nomes = filtra
     */
    public Resultado traduzir(File inputFile, File outputDir,
                              List<String> maquinas, Consumer<String> log) {
        List<String> mensagens = new ArrayList<>();
        Consumer<String> registrar = msg -> {
            mensagens.add(msg);
            if (log != null) log.accept(msg);
        };

        SimGenerator generator = null;
        try {
            // 1. Parse + carrega dependências (uma vez só, mesmo para N máquinas)
            Resource resource = prepararResource(inputFile, registrar);

            // 2. Valida (uma vez só)
            registrar.accept("→ Validando modelo...");
            if (!validarResource(resource, registrar)) {
                return new Resultado(false, mensagens, null);
            }

            // 3. Configura saída
            outputDir.mkdirs();
            JavaIoFileSystemAccess fsa =
                    getInjector().getInstance(JavaIoFileSystemAccess.class);
            fsa.setOutputPath(outputDir.getAbsolutePath());
            generator = getInjector().getInstance(SimGenerator.class);

            registrar.accept("→ Gerando saída em " + outputDir.getAbsolutePath() + "...");

            // 4. Gera — 1 chamada por máquina selecionada
            if (maquinas == null || maquinas.isEmpty()) {
                registrar.accept("→ Filtro: todas as máquinas");
                generator.setSelectedMachine(null);
                generator.doGenerate(resource, fsa, new GeneratorContext());

            } else if (maquinas.size() == 1) {
                String m = maquinas.get(0);
                registrar.accept("→ Filtro: apenas máquina '" + m + "'");
                generator.setSelectedMachine(m);
                generator.doGenerate(resource, fsa, new GeneratorContext());

            } else {
                registrar.accept("→ Filtro: " + maquinas.size() + " máquinas selecionadas");
                for (String m : maquinas) {
                    registrar.accept("   ↳ Gerando '" + m + "'...");
                    generator.setSelectedMachine(m);
                    generator.doGenerate(resource, fsa, new GeneratorContext());
                }
            }

            registrar.accept("\n✅ Tradução concluída!");
            return new Resultado(true, mensagens, outputDir);

        } catch (Exception e) {
            registrar.accept("\n❌ Erro: " + e.getMessage());
            StringBuilder sb = new StringBuilder();
            for (StackTraceElement st : e.getStackTrace()) {
                sb.append("   at ").append(st).append("\n");
            }
            registrar.accept(sb.toString());
            return new Resultado(false, mensagens, null);
        } finally {
            // Garante estado neutro para próximas chamadas
            if (generator != null) {
                generator.setSelectedMachine(null);
            }
        }
    }

    // =========================================================
    // Helpers privados
    // =========================================================

    /** Valida o resource. Retorna false se houver ERRORs. */
    private boolean validarResource(Resource resource, Consumer<String> registrar) {
        IResourceValidator validator =
                getInjector().getInstance(IResourceValidator.class);
        List<Issue> issues = validator.validate(
                resource, CheckMode.ALL, CancelIndicator.NullImpl);

        boolean hasErrors = false;
        for (Issue issue : issues) {
            String linha = "   [" + issue.getSeverity() + "] linha "
                    + issue.getLineNumber() + ": " + issue.getMessage();
            registrar.accept(linha);
            if (issue.getSeverity() == Severity.ERROR) hasErrors = true;
        }
        if (issues.isEmpty()) {
            registrar.accept("   (sem problemas)");
        }
        if (hasErrors) {
            registrar.accept("\n❌ Modelo contém erros de validação. Geração cancelada.");
            return false;
        }
        return true;
    }

    /** Cria ResourceSet, carrega bibliotecas padrão, arquivos irmãos e o arquivo principal. */
    private Resource prepararResource(File inputFile, Consumer<String> log) throws IOException {
        XtextResourceSet rs = getInjector().getInstance(XtextResourceSet.class);

        Path tempLibDir = Files.createTempDirectory("robosim-libs-");
        tempLibDir.toFile().deleteOnExit();

        for (String lib : ROBOCHART_LIBS) {
            Path extracted = extractResource(lib, tempLibDir);
            rs.getResource(URI.createFileURI(extracted.toString()), true);
        }
        for (String lib : ROBOSIM_LIBS) {
            Path extracted = extractResource(lib, tempLibDir);
            rs.getResource(URI.createFileURI(extracted.toString()), true);
        }

        File parentDir = inputFile.getAbsoluteFile().getParentFile();
        if (parentDir != null && parentDir.isDirectory()) {
            File[] siblings = parentDir.listFiles(f ->
                f.getName().endsWith(".rct") || f.getName().endsWith(".rst"));
            if (siblings != null) {
                for (File sib : siblings) {
                    if (!sib.equals(inputFile)) {
                        rs.getResource(URI.createFileURI(sib.getAbsolutePath()), true);
                        if (log != null) log.accept("   • " + sib.getName());
                    }
                }
            }
        }

        URI uri = URI.createFileURI(inputFile.getAbsolutePath());
        Resource resource = rs.getResource(uri, true);
        EcoreUtil.resolveAll(rs);
        return resource;
    }

    private static Path extractResource(String resourcePath, Path destDir) throws IOException {
        try (InputStream in = TraductorService.class.getClassLoader()
                .getResourceAsStream(resourcePath)) {
            if (in == null) {
                throw new IOException("Recurso não encontrado: " + resourcePath);
            }
            Path target = destDir.resolve(resourcePath);
            Files.createDirectories(target.getParent());
            try (OutputStream out = Files.newOutputStream(target)) {
                in.transferTo(out);
            }
            return target;
        }
    }
}