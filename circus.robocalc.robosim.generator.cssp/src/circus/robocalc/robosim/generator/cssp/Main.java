package circus.robocalc.robosim.generator.cssp;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.List;

import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.xtext.generator.GeneratorContext;
import org.eclipse.xtext.generator.JavaIoFileSystemAccess;
import org.eclipse.xtext.resource.XtextResourceSet;
import org.eclipse.xtext.validation.CheckMode;
import org.eclipse.xtext.validation.IResourceValidator;
import org.eclipse.xtext.validation.Issue;
import org.eclipse.xtext.util.CancelIndicator;

import com.google.inject.Injector;

import circus.robocalc.robosim.textual.RoboSimStandaloneSetup;
import circus.robocalc.robosim.generator.cssp.sim.SimGenerator;

public class Main {

    // Bibliotecas padrão a pré-carregar (caminhos dentro dos JARs)
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

    public static void main(String[] args) {
        if (args.length < 1) {
            System.err.println("Uso: java -jar tradutor.jar <arquivo.rst> [pasta-saida]");
            System.exit(1);
        }

        String inputPath = args[0];
        String outputPath = args.length >= 2 ? args[1] : "cssp-gen/sim";

        File inputFile = new File(inputPath);
        if (!inputFile.exists()) {
            System.err.println("Arquivo não encontrado: " + inputPath);
            System.exit(1);
        }

        try {
            traduzir(inputFile, new File(outputPath));
            System.out.println("\n✅ Tradução concluída em: " + outputPath);
        } catch (Exception e) {
            System.err.println("\n❌ Erro durante tradução:");
            e.printStackTrace();
            System.exit(1);
        }
    }

    public static void traduzir(File inputFile, File outputDir) throws Exception {
        // 1. Inicializa o Xtext standalone
        Injector injector = new RoboSimStandaloneSetup()
                .createInjectorAndDoEMFRegistration();

        // 2. Cria o ResourceSet
        XtextResourceSet rs = injector.getInstance(XtextResourceSet.class);

        // 3. Extrai bibliotecas padrão do classpath para uma pasta temp
        Path tempLibDir = Files.createTempDirectory("robosim-libs-");
        tempLibDir.toFile().deleteOnExit();

        System.out.println("Extraindo bibliotecas padrão para: " + tempLibDir);

        for (String lib : ROBOCHART_LIBS) {
            Path extracted = extractResource(lib, tempLibDir);
            rs.getResource(URI.createFileURI(extracted.toString()), true);
            System.out.println("  ✓ " + lib);
        }

        for (String lib : ROBOSIM_LIBS) {
            Path extracted = extractResource(lib, tempLibDir);
            rs.getResource(URI.createFileURI(extracted.toString()), true);
            System.out.println("  ✓ " + lib);
        }

        // 4. Também carrega TODOS os .rct/.rst da pasta do arquivo de entrada
        File parentDir = inputFile.getAbsoluteFile().getParentFile();
        if (parentDir != null && parentDir.isDirectory()) {
            File[] siblings = parentDir.listFiles((f) ->
                f.getName().endsWith(".rct") || f.getName().endsWith(".rst"));
            if (siblings != null) {
                for (File sib : siblings) {
                    if (!sib.equals(inputFile)) {
                        rs.getResource(URI.createFileURI(sib.getAbsolutePath()), true);
                        System.out.println("  ✓ " + sib.getName() + " (do projeto)");
                    }
                }
            }
        }

        // 5. Carrega o arquivo de entrada
        URI uri = URI.createFileURI(inputFile.getAbsolutePath());
        Resource resource = rs.getResource(uri, true);

        // 6. Resolve todas as referências cruzadas
        org.eclipse.emf.ecore.util.EcoreUtil.resolveAll(rs);

        // 7. Valida o modelo
        IResourceValidator validator = injector.getInstance(IResourceValidator.class);
        List<Issue> issues = validator.validate(
                resource, CheckMode.ALL, CancelIndicator.NullImpl);

        boolean hasErrors = false;
        System.out.println("\n--- Validação ---");
        for (Issue issue : issues) {
            System.out.println("[" + issue.getSeverity() + "] linha "
                    + issue.getLineNumber() + ": " + issue.getMessage());
            if (issue.getSeverity() == org.eclipse.xtext.diagnostics.Severity.ERROR) {
                hasErrors = true;
            }
        }
        if (issues.isEmpty()) {
            System.out.println("(sem problemas)");
        }
        if (hasErrors) {
            throw new RuntimeException("Modelo contém erros de validação.");
        }

        // 8. Configura saída e executa o gerador
        outputDir.mkdirs();
        JavaIoFileSystemAccess fsa = injector.getInstance(JavaIoFileSystemAccess.class);
        fsa.setOutputPath(outputDir.getAbsolutePath());

        SimGenerator generator = injector.getInstance(SimGenerator.class);
        System.out.println("\n--- Gerando saída ---");
        generator.doGenerate(resource, fsa, new GeneratorContext());
    }

    /** Extrai um recurso do classpath para a pasta temp. */
    private static Path extractResource(String resourcePath, Path destDir) throws IOException {
        try (InputStream in = Main.class.getClassLoader().getResourceAsStream(resourcePath)) {
            if (in == null) {
                throw new IOException("Recurso não encontrado no classpath: " + resourcePath);
            }
            // Mantém a estrutura de subpastas (lib/robochart/...)
            Path target = destDir.resolve(resourcePath);
            Files.createDirectories(target.getParent());
            try (OutputStream out = Files.newOutputStream(target)) {
                in.transferTo(out);
            }
            return target;
        }
    }
}